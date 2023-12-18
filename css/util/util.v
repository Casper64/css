module util

import css
import css.ast
import css.checker
import css.gen
import css.parser
import css.pref
import os

// parse_file returns `file` in a stylesheet and fills `table` with the css rules
pub fn parse_file(file string, strict bool, mut table ast.Table) !&ast.StyleSheet {
	mut prefs := pref.Preferences{
		is_strict: strict
	}

	mut p := parser.Parser.new(prefs)
	p.table = table
	result := p.parse_file(file)
	p.table.sort_rules()

	// println('== Table: ===============================')
	// println(p.table)
	// println('== StyleSheet: ==========================')

	return result
}

// minify_file doesn't validate the css and only writes a minified version of the file
pub fn minify_file(src_file string, out_file string) ! {
	prefs := pref.Preferences{}
	mut p := parser.Parser.new(prefs)
	p.table = &ast.Table{}
	tree := p.parse_file(src_file)

	minified := gen.generate(tree, gen.GenOptions{
		minify: true
	}, prefs)
	os.write_file(out_file, minified)!
}

// minify_file doesn't validate the css and only writes a prettified version of the file
pub fn prettify_file(src_file string, out_file string) ! {
	prefs := pref.Preferences{}
	mut p := parser.Parser.new(prefs)
	p.table = &ast.Table{}
	tree := p.parse_file(src_file)

	minified := gen.generate(tree, gen.GenOptions{
		minify: false
	}, prefs)
	os.write_file(out_file, minified)!
}

pub fn parse_stylesheet_from_text(src string, prefs pref.Preferences) ![]css.Rule {
	mut table := &ast.Table{}

	mut p := parser.Parser.new(prefs)
	p.table = table
	tree := p.parse_text(src)

	rules := checker.validate(tree, mut table, prefs)!

	return rules
}

pub fn parse_stylesheet(css_file string, prefs pref.Preferences) ![]css.Rule {
	mut table := &ast.Table{}

	mut p := parser.Parser.new(prefs)
	p.table = table
	tree := p.parse_file(css_file)

	rules := checker.validate(tree, mut table, prefs)!

	return rules
}
