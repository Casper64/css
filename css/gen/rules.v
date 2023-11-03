module gen

import css.ast

pub fn (mut g Gen) gen_at_rule(rule ast.AtRule) {
	match rule.typ {
		.unkown {}
		.charset {}
		else {}
	}
}

fn (mut g Gen) gen_normal_rule(rule ast.Rule) {
	// generate selectors
	match rule.prelude {
		ast.Raw {
			g.out.writeln('/* prelude: ast.Raw */')
			g.out.writeln('${rule.prelude.value}${g.space_minify()}{')
		}
		ast.SelectorList {
			selector_list := rule.prelude as ast.SelectorList
			if rule.block.declarations.len == 0 {
				// skip css rule with no declarations
				return
			}

			for i, selector in selector_list.children {
				if selector is ast.Selector {
					g.gen_selector(selector)
				}
				if i != selector_list.children.len - 1 {
					if g.minify {
						g.out.write_string(',')
					} else {
						g.out.writeln(',')
					}
				}
			}
		}
	}
	g.gen_block(rule.block)
}
