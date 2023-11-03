import css.util as css_util
import os

const (
	in_file              = 'css/gen/tests/testdata/pretty.css'
	expected_pretty_file = 'css/gen/tests/testdata/pretty_out.css'
	expected_min_file    = 'css/gen/tests/testdata/pretty_out.min.css'
)

fn test_gen_pretty() {
	out_file := '${os.temp_dir()}/gen_pretty_out.css'
	println(out_file)
	css_util.prettify_file(in_file, out_file)!

	expected := os.read_file(expected_pretty_file)!
	found := os.read_file(out_file)!

	assert clean_line_endings(expected) == clean_line_endings(found)
}

fn test_gen_minify() {
	out_file := '${os.temp_dir()}/gen_minify_out.min.css'
	css_util.minify_file(in_file, out_file)!

	expected := os.read_file(expected_min_file)!
	found := os.read_file(out_file)!

	assert clean_line_endings(expected) == clean_line_endings(found)
}

fn clean_line_endings(s string) string {
	mut res := s.trim_space()
	res = res.replace(' \n', '\n')
	res = res.replace(' \r\n', '\n')
	res = res.replace('\r\n', '\n')
	res = res.trim('\n')
	return res
}
