module gen

import css.ast

fn (mut g Gen) gen_block(block ast.Block) {
	g.indent_level++
	defer {
		g.indent_level--
	}

	g.out.write_string('${g.space_minify()}{')

	for i, decl in block.declarations {
		match decl {
			ast.Raw {}
			ast.Declaration {
				g.gen_declaration(decl, i == block.declarations.len - 1)
			}
			else {}
		}
	}

	if g.minify {
		g.out.write_string('}')
	} else {
		g.out.writeln('\n}\n')
	}
}

fn (mut g Gen) gen_declaration(decl ast.Declaration, is_last bool) {
	if !g.minify {
		g.write_indent()
	}
	g.out.write_string('${decl.property}:${g.space_minify()}')
	g.gen_decl_value(decl.value)

	if decl.important {
		g.out.write_string('${g.space_minify()}!important')
	}

	if (g.minify && !is_last) || !g.minify {
		g.out.write_string(';')
	}
}

fn (mut g Gen) gen_decl_value(value ast.Value) {
	for i, v in value.children {
		mut must_have_seperator := false
		match v {
			ast.Raw {}
			ast.Number {
				g.out.write_string('${v.value}')
				must_have_seperator = true
			}
			ast.Ident {
				g.out.write_string('${v.name}')
				must_have_seperator = true
			}
			ast.String {
				g.out.write_string('"${v.value}"')
			}
			ast.Hash {
				g.out.write_string('#${v.value}')
				must_have_seperator = true
			}
			ast.Operator {
				operator_str := match v.kind {
					.plus {
						must_have_seperator = true
						'+'
					}
					.min {
						must_have_seperator = true
						'-'
					}
					.mul {
						'*'
					}
					.div {
						'/'
					}
					.comma {
						','
					}
				}
				g.out.write_string('${operator_str}')
				if !must_have_seperator {
					g.out.write_string('${g.space_minify()}')
				}
			}
			ast.Parentheses {
				g.out.write_string('(')

				g.parentheses_depth++
				g.gen_decl_value(ast.Value{
					pos: v.pos
					children: v.children
				})
				g.parentheses_depth--

				g.out.write_string(')')
			}
			ast.Dimension {
				g.out.write_string('${v.value}${v.unit}')
				// TODO: check next child
				must_have_seperator = true
			}
			ast.Function {
				g.out.write_string('${v.name}(')

				g.parentheses_depth++
				g.gen_decl_value(ast.Value{
					pos: v.pos
					children: v.children
				})
				g.parentheses_depth--

				g.out.write_string(')')
			}
			else {}
		}
		// don't add a space before ";"
		if must_have_seperator && i != value.children.len - 1 {
			g.out.write_string(' ')
		}
	}
}
