module parser

import css.ast
import css.token

pub fn (mut p Parser) parse_selector() !ast.Selector {
	mut selector := ast.Selector{
		pos: p.tok.pos()
	}

	for {
		start_pos := p.tok.pos()

		// check for difference between `.other .test` and `.other.test`
		// if the position differs one or more places that means a space is between the selectors
		// other tokens should throw errors
		prev_pos := p.prev_tok.pos()
		mut should_have_descenent_selector := start_pos.pos - (prev_pos.pos + prev_pos.len) > 0
			&& selector.children.len > 0 && selector.children.last() !is ast.Combinator

		match p.tok.kind {
			.dot {
				p.next()
				if p.tok.kind != .name {
					// . {}
					return ast.NodeError{
						pos: start_pos.extend(p.tok.pos())
						msg: 'expecting an identifier after "."'
					}
				}
				selector.children << ast.ClassSelector{
					pos: start_pos.extend(p.tok.pos())
					name: p.tok.lit
				}
			}
			.hash {
				p.next()
				if p.tok.kind != .name {
					// color: #;
					return ast.NodeError{
						pos: start_pos.extend(p.tok.pos())
						msg: 'expecting an identifier after "#" in a selector'
					}
				}
				selector.children << ast.IdSelector{
					pos: start_pos.extend(p.tok.pos())
					name: p.tok.lit
				}
			}
			.name {
				selector.children << ast.TypeSelector{
					pos: start_pos.extend(p.tok.pos())
					name: p.tok.lit
				}
			}
			.mul {
				selector.children << ast.TypeSelector{
					pos: start_pos.extend(p.tok.pos())
					name: '*'
				}
			}
			.colon {
				// if p.inside_pseudo_selector {
				// 	p.unexpected(got: 'token ${p.tok.kind}')
				// 	return ast.NodeError{
				// 		pos: start_pos.extend(p.tok.pos())
				// 		msg: 'You can not have a pseudo selector inside of a pseudo selector'
				// 	}
				// }

				p.next()
				if p.tok.kind == .colon || p.tok.kind == .name {
					// :
					if p.tok.kind == .colon {
						// ::
						p.is_pseudo_element = true
						p.next()
					}
					selector.children << p.parse_pseudo_selector() or {
						p.is_pseudo_element = false
						return err
					}
					p.is_pseudo_element = false
				} else {
					// .test: {}
					return ast.NodeError{
						pos: start_pos.extend(p.tok.pos())
						msg: 'expecting an identifier or ":" after ":" in a selector'
					}
				}
			}
			.rpar {
				if p.inside_pseudo_selector {
					break
				} else {
					// :not.test)
					return ast.NodeError{
						pos: start_pos.extend(p.tok.pos())
						msg: 'expecting a "(" before ")" inside a selector'
					}
				}
			}
			.lsbr {
				if p.peek_tok.kind != .name {
					// a[] {}
					return ast.NodeError{
						pos: start_pos.extend(p.tok.pos())
						msg: 'expecting an identifier'
					}
				}

				selector.children << p.parse_attr()!
			}
			// combinators
			.gt {
				should_have_descenent_selector = false
				selector.children << ast.Combinator{
					pos: start_pos.extend(p.tok.pos())
					kind: '>'
				}
			}
			.plus {
				should_have_descenent_selector = false
				selector.children << ast.Combinator{
					pos: start_pos.extend(p.tok.pos())
					kind: '+'
				}
			}
			else {
				break
			}
		}

		if should_have_descenent_selector {
			// insert combinator in between `.test .other`
			selector.children.insert(selector.children.len - 1, ast.Combinator{
				pos: token.Pos{
					len: start_pos.pos - (prev_pos.pos + prev_pos.len)
					pos: prev_pos.pos + prev_pos.len
					col: prev_pos.col + prev_pos.len
				}
				kind: ' '
			})
		}

		p.next()
	}

	selector.pos.extend(p.tok.pos())
	return selector
}

pub fn (mut p Parser) parse_pseudo_selector() !ast.PseudoSelector {
	pseudo_start := p.tok.pos()

	if p.tok.kind != .name {
		// .test: {}
		return ast.NodeError{
			pos: pseudo_start.extend(p.tok.pos())
			msg: 'expecting a name after a pseudo class selector ":"'
		}
	}
	pseudo_selector_name := p.tok.lit

	// :not()
	if p.peek_tok.kind == .lpar {
		if p.inside_pseudo_selector {
			// :not(.test:has(.other))
			return ast.NodeError{
				pos: p.tok.pos()
				msg: 'You can not have a pseudo selector function inside of a pseudo selector function'
			}
		}

		p.next()
		p.next()

		p.inside_pseudo_selector = true
		sub_selector := p.parse_selector() or {
			p.inside_pseudo_selector = false

			// continue until ")"
			for p.tok.kind != .rpar {
				p.next()
			}

			if err is ast.NodeError {
				p.error_with_pos(err.msg(), err.pos)
				return ast.Raw{
					value: p.lexer.get_lit(err.pos.pos, p.tok.pos().pos)
					pos: err.pos.extend(p.tok.pos())
				}
			}

			return err
		}
		p.inside_pseudo_selector = false
		if p.tok.kind != .rpar {
			// :not( {
			return ast.NodeError{
				pos: p.tok.pos()
				msg: 'expecting a closing parenthesis ")" after a pseudo selector'
			}
		}

		if p.is_pseudo_element {
			return ast.PseudoElementSelector{
				pos: pseudo_start.extend(p.tok.pos())
				name: pseudo_selector_name
				children: sub_selector.children
			}
		} else {
			return ast.PseudoClassSelector{
				pos: pseudo_start.extend(p.tok.pos())
				name: pseudo_selector_name
				children: sub_selector.children
			}
		}
	} else {
		// :first-child
		if p.is_pseudo_element {
			return ast.PseudoElementSelector{
				pos: pseudo_start.extend(p.tok.pos())
				name: pseudo_selector_name
			}
		} else {
			return ast.PseudoClassSelector{
				pos: pseudo_start.extend(p.tok.pos())
				name: pseudo_selector_name
			}
		}
	}
}

pub fn (mut p Parser) parse_attr() !ast.AttributeSelector {
	attr_start := p.tok.pos()

	p.next()
	attr_name := ast.Ident{
		pos: p.tok.pos()
		name: p.tok.lit
	}
	p.next()

	mut should_check_equals := true
	attr_match_type := match p.tok.kind {
		.equal {
			// a[href="#test"]
			should_check_equals = false
			ast.AttributeMatchType.exact
		}
		.carrot {
			// a[href^="#test"]
			ast.AttributeMatchType.starts_with
		}
		.mul {
			// a[href*="#test"]
			ast.AttributeMatchType.contains
		}
		.dollar {
			// a[href$="#test"]
			ast.AttributeMatchType.ends_with
		}
		.rsbr {
			// a[href]
			return ast.AttributeSelector{
				pos: attr_start.extend(p.tok.pos())
				name: attr_name
			}
		}
		else {
			return ast.NodeError{
				pos: attr_start.extend(p.tok.pos())
				msg: 'unexpected token'
			}
		}
	}

	if should_check_equals {
		p.next()
		if p.tok.kind != .equal {
			// a[href^test]
			return ast.NodeError{
				pos: p.tok.pos()
				msg: 'expecting "=" after the attribute match type'
			}
		}
	}

	p.next()
	if p.tok.kind != .string {
		if p.tok.kind != .name || p.prefs.is_strict {
			// a[href=#test]
			return ast.NodeError{
				pos: p.tok.pos()
				msg: 'expected a string after "=" inside the attribute selector'
			}
		}
		// else {
		// 	p.warn('expected a string after "=" inside the attribute selector')
		// }
	}
	attr_value := p.tok.lit
	p.next()
	if p.tok.kind != .rsbr {
		// a[href="#test" {}
		return ast.NodeError{
			pos: p.tok.pos()
			msg: 'expecting a "]" to close the attribute selector'
		}
	}

	return ast.AttributeSelector{
		pos: attr_start.extend(p.tok.pos())
		name: attr_name
		matcher: attr_match_type
		value: ast.String{
			pos: p.tok.pos()
			value: attr_value
		}
	}
}
