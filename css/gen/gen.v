module gen

import css.ast
import css.pref
import strings

@[params]
pub struct GenOptions {
	minify bool
}

pub struct Gen {
	prefs      pref.Preferences
	minify     bool
	stylesheet &ast.StyleSheet
mut:
	out               strings.Builder
	indent_level      int
	parentheses_depth int
}

pub fn generate(stylesheet &ast.StyleSheet, opts GenOptions, prefs pref.Preferences) string {
	mut global_g := &Gen{
		prefs: prefs
		minify: opts.minify
		stylesheet: stylesheet
		out: strings.new_builder(640000)
	}

	return global_g.gen_file()
}

pub fn (mut g Gen) gen_file() string {
	for rule in g.stylesheet.rules {
		match rule {
			ast.AtRule {
				g.gen_at_rule(rule)
			}
			ast.Rule {
				g.gen_normal_rule(rule)
			}
			else {}
		}
	}

	out_str := g.out.str()
	unsafe {
		g.out.free()
	}
	return out_str
}

fn (mut g Gen) write_indent() {
	g.out.write_string('\n')
	for _ in 0 .. g.indent_level {
		g.out.write_string('    ')
	}
}

fn (mut g Gen) space_minify() string {
	if !g.minify {
		return ' '
	}
	return ''
}
