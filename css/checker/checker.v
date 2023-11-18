module checker

import css
import css.ast
import css.pref
import css.errors
import css.token

// Validator is an interface which you can extend to check any custom properties
pub interface Validator {
	validate_property(string, ast.Value) !css.Value
	set_grouped(prop_name string, value css.Value, mut style_map map[string]css.RawValue) bool
}

// seperating the property validator from the checker means that the validator
// can be extended by embedding it allowing custom properties and the ability
// to override default behaviour of css values.
// You can make an instance of Property by calling the `make_property_validator`
// on an instance of `Checker`
@[noinit]
pub struct PropertyValidator {
	get_details    fn () string = unsafe { nil }
	warn_with_pos  fn (string, token.Pos) = unsafe { nil }
	error_with_pos fn (string, token.Pos) ast.NodeError = unsafe { nil }
}

pub fn (pv &PropertyValidator) unsupported_property(property string) string {
	return 'unsupported property "${property}"! Check the "CAN_I_USE.md" for a list of supported properties'
}

pub fn validate(tree &ast.StyleSheet, mut table ast.Table, prefs &pref.Preferences) ![]css.Rule {
	mut checker := &Checker{
		file_path: tree.file_path
		prefs: prefs
		table: table
		rules: []css.Rule{cap: tree.rules.len}
	}
	checker.validator = checker.make_property_validator()

	checker.validate(tree)
	if checker.has_errored {
		return error('checker has returned with errors!')
	}

	checker.sort_rules()
	return checker.rules
}

@[heap; minify]
pub struct Checker {
	prefs     &pref.Preferences
	file_path string
mut:
	error_details []string
	validator     Validator @[noinit]
pub mut:
	table       &ast.Table = unsafe { nil }
	has_errored bool
	rules       []css.Rule
}

// make_property_validator returns a new `PropertyValidator` instance and sets the error functions
pub fn (c Checker) make_property_validator() PropertyValidator {
	return PropertyValidator{
		get_details: c.get_details
		warn_with_pos: c.warn_with_pos
		error_with_pos: c.error_with_pos
	}
}

pub fn (mut c Checker) sort_rules() {
	c.rules.sort(|a, b| a.specificity <= b.specificity)
}

pub fn (mut c Checker) validate(tree &ast.StyleSheet) {
	for rule in tree.rules {
		match rule {
			ast.Rule {
				c.validate_rule(rule) or {
					if err is ast.NodeError {
						c.error_with_pos(err.msg, err.pos)
					} else {
						c.error(err.msg())
					}
					continue
				}
			}
			ast.KeyframesRule {}
			else {}
		}
	}
}

pub fn (mut c Checker) get_details() string {
	mut details := ''
	if c.error_details.len > 0 {
		details = '\n' + c.error_details.join('\n')
		c.error_details = []
	}
	return details
}

pub fn (mut c Checker) warn_with_pos(msg string, pos token.Pos) {
	details := c.get_details()
	if !c.prefs.suppress_output {
		errors.show_compiler_message('warning:',
			msg: msg
			details: details
			file_path: c.file_path
			pos: pos
		)
	}
}

pub fn (mut c Checker) error(msg string) ast.NodeError {
	c.has_errored = true
	details := c.get_details()

	// TODO: better handle normal errors
	eprintln(msg)
	eprintln('details: ${details}')

	return ast.NodeError{
		msg: msg
	}
}

pub fn (mut c Checker) error_with_pos(msg string, pos token.Pos) ast.NodeError {
	c.has_errored = true
	details := c.get_details()

	if !c.prefs.suppress_output {
		errors.show_compiler_message('error:',
			msg: msg
			details: details
			file_path: c.file_path
			pos: pos
		)
	}

	return ast.NodeError{
		msg: msg
		pos: pos
	}
}
