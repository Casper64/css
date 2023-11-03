module parser

import css.ast

pub fn (mut p Parser) at_decl() ast.AtRule {
	if p.tok.lit.len == 0 {
		p.error_with_pos('expecting a name after "@"', p.tok.pos())
		p.next()
		return ast.AtRule{}
	}

	mut rule := match p.tok.lit {
		'import' {
			p.error('@import rules can only occur at the top of the file!')
			ast.AtRule{}
		}
		'charset' {
			p.parse_at_charset() or {
				p.recover_until(.semicolon)
				// ???
				// skip ";"
				// ast.Raw{
				// 	value: p.lexer.get_lit(err.pos.pos, p.tok.pos().pos)
				// 	pos: err.pos.extend(p.tok.pos())
				// }
				ast.AtRule{}
			}
		}
		'layer' {
			p.parse_at_layer()
		}
		'media' {
			p.parse_at_media()
		}
		'keyframes', '-webkit-keyframes' {
			p.parse_at_keyframes() or {
				p.skip_block()
				return ast.AtRule{}
			}
		}
		else {
			p.warn('unkown at-rule "${p.tok.lit}"')
			p.skip_block()
			return ast.AtRule{}
		}
	}
	p.next()
	return rule
}

pub fn (mut p Parser) parse_at_charset() !ast.AtRule {
	charset_start := p.tok.pos()
	// skip @charset
	p.next()

	mut charset := ''
	if p.tok.kind == .string && p.tok.meta == double_quote {
		charset = p.tok.lit
	} else {
		// @charset 'test';
		return p.error('invalid charset rule: expecting a double quoted string after "@charset"')
	}

	// todo extrapolate in function?
	p.next()
	if p.tok.kind != .semicolon {
		return p.error('expecting a semicolon to close the at-rule')
	}
	if p.tok.pos != p.prev_tok.pos + p.prev_tok.len {
		return p.error('the ";" has to be the next character after "${charset}"')
	}

	return ast.AtRule{
		pos: charset_start.extend(p.tok.pos())
		typ: .charset
		prelude: [ast.String{
			pos: p.tok.pos()
			value: charset
		}]
	}
}

pub fn (mut p Parser) parse_at_layer() ast.AtRule {
	layer_start := p.tok.pos()
	// skip @layer
	p.next()

	mut layer_names := []ast.Node{}
	mut comma_count := 0
	mut children := []ast.Node{}

	for {
		match p.tok.kind {
			.name {
				if comma_count != layer_names.len {
					p.warn('expecting a comma separated list. Missing "," before "${p.tok.lit}"')
				}
				layer_names << ast.Ident{
					pos: p.tok.pos()
					name: p.tok.lit
				}
			}
			.comma {
				comma_count++
				if comma_count != layer_names.len {
					p.warn('expecting a name, ";" or "{" not ","')
					comma_count--
				}
			}
			.lcbr {
				p.next()
				for {
					if p.tok.kind == .eof || p.tok.kind == .rcbr {
						break
					}
					rule := p.top_rule()
					children << rule
				}
				if p.tok.kind != .rcbr {
					p.error('expecting "}". Did you forget to close the previous block?')
				}
				break
			}
			.semicolon {
				break
			}
			else {
				p.unexpected(got: ' token ${p.tok.kind}')
				return ast.AtRule{}
			}
		}
		p.next()
	}

	return ast.AtRule{
		pos: layer_start.extend(p.tok.pos())
		typ: .layer
		prelude: layer_names
		children: children
	}
}

pub fn (mut p Parser) parse_at_media() ast.AtRule {
	media_start := p.tok.pos()
	// skip @media
	p.next()

	mut media_list_pos := p.tok.pos()
	mut query_start := p.tok.pos()
	mut queries := []ast.MediaQuery{}
	mut current_children := []ast.Node{}

	mut media_rules := []ast.Node{}

	for {
		match p.tok.kind {
			.name {
				current_children << ast.Ident{
					pos: p.tok.pos()
					name: p.tok.lit
				}
			}
			.lpar {
				if c := p.parse_at_media_feature() {
					current_children << c
				}
			}
			.lcbr {
				queries << ast.MediaQuery{
					pos: query_start.extend(p.tok.pos())
					children: current_children
				}
				media_list_pos = media_list_pos.extend(p.tok.pos())
				p.next()
				for {
					if p.tok.kind == .eof || p.tok.kind == .rcbr {
						break
					}
					rule := p.top_rule()
					media_rules << rule
				}
				if p.tok.kind != .rcbr {
					p.error('expecting "}". Did you forget to close the previous block?')
				}
				break
			}
			.comma {
				if current_children.len == 0 || p.peek_tok.kind == .lcbr {
					p.warn('expecting a media query or "{"')
				} else {
					queries << ast.MediaQuery{
						pos: query_start.extend(p.tok.pos())
						children: current_children
					}
					current_children.clear()
					query_start = p.peek_tok.pos()
				}
			}
			else {
				p.unexpected(got: 'token ${p.tok.kind}')
			}
		}
		p.next()
	}

	return ast.AtRule{
		pos: media_start.extend(p.tok.pos())
		typ: .media
		prelude: [ast.MediaQueryList{
			pos: media_list_pos
			children: queries
		}]
		children: media_rules
	}
}

pub fn (mut p Parser) parse_at_media_feature() !ast.MediaFeature {
	feature_start := p.tok.pos()
	// skip "("
	p.next()

	mut media_name := ''
	mut media_value := ?ast.Node(none)
	mut has_value := false

	for {
		match p.tok.kind {
			.name {
				if !has_value {
					media_name = p.tok.lit
				} else if media_value != none {
					// @media (hover: hover hover)
					return p.error('unexpected token: expecting ")"')
				} else {
					media_value = ast.Ident{
						pos: p.tok.pos()
						name: p.tok.lit
					}
				}
			}
			.number {
				if media_value != none {
					// @media (hover : 600px 600px)
					return p.error('unexpected token: expecting ")"')
				}
				media_value = p.parse_dimension()
			}
			.rpar {
				if has_value && media_value == none {
					// @media (min-width:)
					return p.error('unexpected token: expecting a term')
				}
				break
			}
			.colon {
				if has_value {
					// @media (min-width: test :)
					return p.error('unexpected token: expecting ")"')
				}
				has_value = true
			}
			else {
				return p.unexpected()
			}
		}
		p.next()
	}

	return ast.MediaFeature{
		pos: feature_start.extend(p.tok.pos())
		name: media_name
		value: media_value
	}
}

pub fn (mut p Parser) parse_at_keyframes() !ast.AtRule {
	keyframes_start := p.tok.pos()
	// skip @keyframes
	p.next()

	if p.tok.kind != .name {
		// @keyframes {}
		return p.error('expecting the name of the keyframes rule')
	}
	keyframe_name := ast.Ident{
		pos: p.tok.pos()
		name: p.tok.lit
	}

	p.next()
	if p.tok.kind != .lcbr {
		// @keyframes name ... }
		return p.error('expecting "{"')
	}

	// skip "{"
	p.next()

	mut keyframe_rules := []ast.Node{}
	mut current_percentage := ?string(none)

	for {
		match p.tok.kind {
			.name {
				if current_percentage != none {
					p.error('expecting "{"')
					p.recover_until(.rcbr)
					current_percentage = none
				} else if p.tok.lit != 'from' && p.tok.lit != 'to' {
					// .test {}
					p.error('expecting a percentage or "from" or "to"')
					p.skip_block()
					continue
				} else {
					current_percentage = if p.tok.lit == 'from' {
						'0'
					} else {
						'100'
					}
				}
			}
			.number {
				if current_percentage != none {
					p.error('expecting "{"')
					p.recover_until(.rcbr)
					current_percentage = none
				} else if p.peek_tok.kind != .percentage {
					// 50 {}
					p.error('expecting a percentage or "from" or "to"')
					p.skip_block()
					continue
				} else {
					current_percentage = p.tok.lit
					// skip "50%"
					p.next()
				}
			}
			.lcbr {
				if percentage := current_percentage {
					rule_start := p.tok.pos()
					// skip "{"
					p.next()
					declarations := p.parse_declaration_block()
					if p.tok.kind != .rcbr {
						p.error('expecting "}". Did you forget to close the previous block?')
						break
					} else {
						keyframe_rules << ast.KeyframesRule{
							pos: rule_start.extend(p.tok.pos())
							percentage: percentage
							declarations: declarations
						}

						current_percentage = none
					}
				} else {
					p.error('expecting a percentage or "from" or "to" before a keyframes rule')
					p.skip_block()
					continue
				}
			}
			.rcbr {
				break
			}
			else {
				return p.error('expecting a keyframes rule')
			}
		}
		p.next()
	}

	return ast.AtRule{
		pos: keyframes_start.extend(p.tok.pos())
		typ: .keyframes
		prelude: [keyframe_name]
		children: keyframe_rules
	}
}
