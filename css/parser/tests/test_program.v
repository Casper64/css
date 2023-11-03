import css
import css.ast
import css.parser
import css.pref
import os

fn main() {
	if os.args.len < 2 {
		panic('usage: v run main.v CSS_FILE [--strict]')
	}

	is_strict := '--strict' in os.args
	mut prefs := pref.Preferences{
		is_strict: is_strict
	}

	mut p := parser.Parser.new(prefs)
	p.table = &ast.Table{}
	p.parse_file(os.args[1])
}
