module checker

import css
import css.ast

// pub fn (mut c Checker) validate_rule(rule ast.RuleNode) !css.Rule {
// 	// TODO: make this faster??
// 	selectors := c.validate_selector_list(rule.selector.children)!

// 	if c.tmp_declarations[rule.declaration_idx].len != 0 {
// 		return css.Rule{
// 			specificity: css.Specificity.from_selectors(selectors)
// 			selectors: selectors
// 			declarations: c.tmp_declarations[rule.declaration_idx].clone()
// 		}
// 	} else {
// 		decls := c.validate_declarations(c.table.raw_declarations[rule.declaration_idx])
// 		c.tmp_declarations[rule.declaration_idx] = decls.clone()
// 		return css.Rule{
// 			specificity: css.Specificity.from_selectors(selectors)
// 			selectors: selectors
// 			declarations: decls
// 		}
// 	}
// }

pub fn (mut c Checker) validate_rule(rule ast.Rule) ! {
	if rule.prelude is ast.Raw {
		return ast.NodeError{
			msg: 'invalid selector list'
			pos: rule.prelude.pos
		}
	}

	mut valid_selector_list := [][]css.Selector{}

	selector_list := rule.prelude as ast.SelectorList
	for selector in selector_list.children {
		if selector is ast.Selector {
			if list := c.validate_selector_list(selector.children) {
				valid_selector_list << [list]
			} else {
				if err is ast.NodeError {
					c.error_with_pos(err.msg(), err.pos)
				} else {
					c.error(err.msg())
				}
			}
		} else {
			return ast.NodeError{
				msg: 'invalid selectors'
				pos: selector.pos()
			}
		}
	}

	valid_declarations := c.validate_declarations(rule.block.declarations)

	for selectors in valid_selector_list {
		c.rules << css.Rule{
			specificity: css.Specificity.from_selectors(selectors)
			selectors: selectors
			declarations: valid_declarations
		}
	}
}

pub fn (mut c Checker) validate_selector_list(selectors []ast.Node) ![]css.Selector {
	mut valid_selectors := []css.Selector{}

	for i, s in selectors {
		valid_selectors << match s {
			ast.ClassSelector {
				css.Selector(css.Class(s.name))
			}
			ast.TypeSelector {
				css.Type(s.name)
			}
			ast.IdSelector {
				css.Id(s.name)
			}
			ast.AttributeSelector {
				mut attr := css.Attribute{
					name: s.name.name
					matcher: s.matcher
				}
				if v := s.value {
					attr.value = v.value
				}

				attr
			}
			ast.PseudoSelector {
				match s {
					ast.PseudoClassSelector {
						if s.children.len > 0 && s.name !in pseudo_class_selectors_functions {
							return ast.NodeError{
								msg: 'pseudo class selector "${s.name}" is not a function'
								pos: s.pos
							}
						} else if s.children.len == 0 && s.name in pseudo_class_selectors_functions {
							return ast.NodeError{
								msg: 'expected pseudo class selector "${s.name}" to be a function'
								pos: s.pos
							}
						}
						// TODO: verify name + function arguments
						valid_list := c.validate_selector_list(s.children)!
						css.Selector(css.PseudoClass{
							name: s.name
							children: valid_list
						})
					}
					ast.PseudoElementSelector {
						if s.children.len > 0 && s.name !in pseudo_element_selectors_functions {
							return ast.NodeError{
								msg: 'pseudo element selector "${s.name}" is not a function'
								pos: s.pos
							}
						} else if s.children.len == 0
							&& s.name in pseudo_element_selectors_functions {
							return ast.NodeError{
								msg: 'expected pseudo element selector "${s.name}" to be a function'
								pos: s.pos
							}
						}
						valid_list := c.validate_selector_list(s.children)!
						css.PseudoElement{
							name: s.name
							children: valid_list
						}
					}
					else {
						return ast.NodeError{
							msg: 'invalid or unsupported selector'
							pos: s.pos
						}
					}
				}
			}
			ast.Combinator {
				if i == selectors.len - 1 {
					return ast.NodeError{
						msg: 'unexpected combinator: a combinator cannot be the last part of a CSS selector'
						pos: s.pos
					}
				}
				css.Combinator(s.kind)
			}
			else {
				return ast.NodeError{
					msg: 'invalid or unsupported selector'
					pos: s.pos()
				}
			}
		}
	}

	return valid_selectors
}
