import css.ast
import css.parser
import css.pref

const (
	css_file     = '${@VMODROOT}/tests/testdata/bootstrap.css'
	min_css_file = '${@VMODROOT}/tests/testdata/bootstrap.min.css'
)

fn test_parser_no_errors() {
	mut p := parser.Parser.new(&pref.Preferences{
		suppress_output: true
		is_strict: true
	})
	p.table = &ast.Table{}
	p.parse_file(css_file)

	assert p.has_errored == false
}

fn test_parser_no_errors_minified() {
	mut p := parser.Parser.new(&pref.Preferences{
		suppress_output: true
	})
	p.table = &ast.Table{}
	p.parse_file(min_css_file)

	assert p.has_errored == false
}
