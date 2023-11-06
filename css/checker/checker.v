module checker

import css
import css.ast
import css.pref
import css.errors
import css.token

pub interface Validator {
	validate_property(property string, raw_value ast.Value) !css.Value
}

// seperating the property validator from the checker means that the validator
// can be extended by embedding it allowing custom properties and the ability
// to override default behaviour of css values
pub struct PropertyValidator {}

pub fn (pv &PropertyValidator) unsupported_property(property string) string {
	return 'unsupported property "${property}"! Check the "CAN_I_USE.md" for a list of supported properties'
}

pub fn validate(tree &ast.StyleSheet, mut table ast.Table, prefs &pref.Preferences) ![]css.Rule {
	mut checker := &Checker{
		file_path: tree.file_path
		prefs: prefs
		table: table
		validator: PropertyValidator{}
		rules: []css.Rule{cap: tree.rules.len}
	}

	checker.validate(tree)
	if checker.has_errored {
		return error('checker has returned with errors!')
	}

	checker.sort_rules()
	return checker.rules
}

[heap; minify]
pub struct Checker {
	prefs     &pref.Preferences
	file_path string
mut:
	error_details []string
	validator     Validator
pub mut:
	table       &ast.Table = unsafe { nil }
	has_errored bool
	rules       []css.Rule
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
