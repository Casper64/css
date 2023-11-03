module gen

import css.ast

fn (mut g Gen) gen_selector(selector ast.Selector) {
	for s in selector.children {
		match s {
			ast.ClassSelector {
				g.out.write_string('.${s.name}')
			}
			ast.TypeSelector {
				g.out.write_string(s.name)
			}
			ast.IdSelector {
				g.out.write_string('#${s.name}')
			}
			ast.Combinator {
				if s.kind != ' ' {
					g.out.write_string('${g.space_minify()}${s.kind}${g.space_minify()}')
				} else {
					g.out.write_string(' ')
				}
			}
			ast.PseudoSelector {
				g.gen_pseudo_selector(s)
			}
			ast.AttributeSelector {
				g.gen_attr_selector(s)
			}
			else {}
		}
	}
}

fn (mut g Gen) gen_pseudo_selector(s ast.PseudoSelector) {
	match s {
		ast.Raw {}
		ast.PseudoClassSelector, ast.PseudoElementSelector {
			g.out.write_string(':${s.name}')
			if s is ast.PseudoElementSelector {
				g.out.write_string(':${s.name}')
			}

			if s.children.len > 0 {
				g.out.write_string('(')
				g.gen_selector(ast.Selector{
					pos: s.pos
					children: s.children
				})
				g.out.write_string(')')
			}
		}
	}
}

fn (mut g Gen) gen_attr_selector(attr ast.AttributeSelector) {
	g.out.write_string('[${attr.name.name}')

	match attr.matcher {
		.exact {
			g.out.write_string('=')
		}
		.contains {
			g.out.write_string('*=')
		}
		.starts_with {
			g.out.write_string('^=')
		}
		.ends_with {
			g.out.write_string('$=')
		}
		.@none {}
	}

	if v := attr.value {
		g.out.write_string('"${v.value}"')
	}
	g.out.write_string(']')
}
