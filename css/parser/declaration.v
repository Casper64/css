module parser

import css.ast

pub fn (mut p Parser) parse_declaration_block() []ast.Node {
	mut declarations := []ast.Node{}

	for {
		if p.tok.kind == .rcbr || p.tok.kind == .eof {
			break
		}

		if decl := p.parse_declaration() {
			declarations << decl
		} else {
			// continue to next line
			for p.tok.kind !in [.semicolon, .rcbr, .eof] {
				p.next()
			}
			// prevent parser from getting stuck e.g. "color: green;;"
			if p.tok.kind == .semicolon {
				p.next()
			}

			if err is ast.NodeError {
				declarations << ast.Raw{
					value: p.lexer.get_lit(err.pos.pos, p.tok.pos().pos)
					pos: err.pos.extend(p.tok.pos())
				}
			} else {
				p.error(err.msg())
			}
		}
	}

	return declarations
}

pub fn (mut p Parser) parse_declaration() !ast.Declaration {
	defer {
		p.is_important = false
	}
	start_pos := p.tok.pos()

	if p.tok.kind != .name {
		// .test { ; }
		return p.error('unexpected token, expecting a property name or "}"')
	}

	property := p.tok.lit
	p.next()
	if p.tok.kind != .colon {
		// .test { color green; }
		return p.error('expecting ":" after a property name')
	}
	p.next()

	value_pos := p.tok.pos()
	values := p.parse_value_children()!
	mut value := ast.Value{
		pos: value_pos.extend(p.tok.pos())
		children: values
	}

	return ast.Declaration{
		pos: start_pos.extend(p.tok.pos())
		property: property
		value: value
		important: p.is_important
	}
}

pub fn (mut p Parser) parse_value_children() ![]ast.Node {
	mut children := []ast.Node{}
	for {
		match p.tok.kind {
			.exclamation {
				p.next()
				important_pos := p.prev_tok.pos().extend(p.tok.pos())
				// color: !asdsd;
				if p.tok.kind != .name || p.tok.lit != 'important' {
					return p.error_with_pos('expecting "!important"', important_pos)
				} else {
					// color: !important;
					if children.len == 0 {
						return p.error_with_pos('expecting a value before "!important"',
							important_pos)
					}
					p.is_important = true
					// color: red !important green;
					if p.peek_tok.kind != .semicolon && p.peek_tok.kind != .rcbr {
						return p.error_with_pos('expecting ";": "!important" has to be the last identifier in a declaration',
							important_pos)
					}
				}
			}
			.number {
				// if the tokens are directly next to each other it's a dimension: 100px
				// otherwise it's a number and something else: rgb(0 0 0)
				if p.tok.pos().pos + p.tok.pos().len == p.peek_tok.pos().pos
					&& (p.peek_tok.kind == .name || p.peek_tok.kind == .percentage) {
					children << p.parse_dimension()
				} else {
					children << ast.Number{
						pos: p.tok.pos()
						value: p.tok.lit
					}
				}
			}
			.name {
				if p.peek_tok.kind == .lpar {
					children << p.parse_function()!
				} else {
					children << ast.Ident{
						pos: p.tok.pos()
						name: p.tok.lit
					}
				}
			}
			.string {
				// e.g. content: "stuff";
				children << ast.String{
					pos: p.tok.pos()
					value: p.tok.lit
				}
			}
			.hash {
				hash_start := p.tok.pos()
				if p.peek_tok.kind != .color {
					// color: #;
					return p.error_with_pos('expecting a hex color', hash_start.extend(p.peek_tok.pos()))
				}
				p.next()
				p.validate_hex_color(p.tok.lit)!
				children << ast.Hash{
					pos: hash_start.extend(p.tok.pos())
					value: p.tok.lit
				}
			}
			// operators
			.comma {
				children << ast.Operator{
					pos: p.tok.pos()
					kind: .comma
				}
			}
			.plus {
				children << ast.Operator{
					pos: p.tok.pos()
					kind: .plus
				}
			}
			.minus {
				children << ast.Operator{
					pos: p.tok.pos()
					kind: .min
				}
			}
			.mul {
				children << ast.Operator{
					pos: p.tok.pos()
					kind: .mul
				}
			}
			.div {
				children << ast.Operator{
					pos: p.tok.pos()
					kind: .div
				}
			}
			.rcbr {
				// it's actually valid css syntax if you don't place a semicolon after the last
				// declaration in a block
				if p.prefs.is_strict {
					return p.error('expecting ";"')
				}
				return children
			}
			.lpar {
				children << p.parse_parentheses()!
			}
			.rpar {
				if p.parentheses_depth <= 0 {
					return p.error('unexpected ")" there is no matching opening parenthesis')
				}
				return children
			}
			.semicolon {
				if p.parentheses_depth > 0 {
					// :not(.test  { color: green; }
					//           ^
					return p.error('unexpected ";" inside a function, expecting ")". Did you forget to close the parentheses?')
				}
				break
			}
			else {
				return p.unexpected()
			}
		}
		p.next()
	}
	// skip ';'
	p.next()

	return children
}

pub fn (mut p Parser) parse_dimension() ast.Dimension {
	start_pos := p.tok.pos()
	value := p.tok.lit
	p.next()
	unit := p.tok.lit
	return ast.Dimension{
		pos: start_pos.extend(p.tok.pos())
		value: value
		unit: unit
	}
}

pub fn (mut p Parser) parse_parentheses() !ast.Parentheses {
	par_start := p.tok.pos()
	p.next()

	p.parentheses_depth++
	children := p.parse_value_children()!
	p.parentheses_depth--

	return ast.Parentheses{
		pos: par_start.extend(p.tok.pos())
		children: children
	}
}

pub fn (mut p Parser) parse_function() !ast.Function {
	fn_start := p.tok.pos()

	fn_name := p.tok.lit
	// skip "("
	p.next()
	p.next()
	p.parentheses_depth++
	defer {
		p.parentheses_depth--
	}
	children := p.parse_value_children()!

	if p.tok.kind != .rpar {
		return p.error('expecting closing parenthesis ")" not ${p.tok.kind}')
	}
	return ast.Function{
		pos: fn_start.extend(p.tok.pos())
		name: fn_name
		children: children
	}
}

// returns error if not valid
pub fn (mut p Parser) validate_hex_color(val string) ! {
	if val.to_lower().contains_only('abcdef0123456789') == false {
		return p.error('invalid hex color')
	}

	// TODO: handle this in checker?

	// check if the next token is next to the color and if that token is not ; or , or ! or }
	// that means it is an invalid hex color
	// #0000zz
	// #0000width
	if p.peek_tok.kind !in [.comma, .semicolon, .rcbr, .exclamation]
		&& p.peek_tok.pos == p.tok.pos + p.tok.len {
		return p.error_with_pos('invalid hex color', p.tok.pos().extend(p.peek_tok.pos()))
	}
}
