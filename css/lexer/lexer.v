module lexer

import css.errors
import css.pref
import css.token
import os

const single_quote = `'`
const double_quote = `"`
const backslash = `\\`
const b_lf = 10
const b_cr = 13

pub fn new_lexer_file(prefs pref.Preferences, file_path string) !&Lexer {
	if !os.is_file(file_path) {
		return error('${file_path} is not a .css file')
	}
	raw_text := os.read_file(file_path)!

	mut l := &Lexer{
		prefs: prefs
		all_tokens: []token.Token{cap: raw_text.len / 3}
		text: raw_text
		file_path: file_path
	}

	l.scan_remaining_text()
	l.tidx = 0
	return l
}

pub struct Lexer {
	prefs pref.Preferences
pub:
	file_path string
pub mut:
	text             string // the whole text of the file
	pos              int    // current position in the file, first character is l.text[0]
	all_tokens       []token.Token
	line_nr          int // current line number
	last_nl_pos      int = -1 // for calculating column
	nr_lines         int // total number of lines in the source file that were scanned
	quote            u8  // the current quote
	is_started       bool
	is_inside_string bool
	is_inside_rule   bool
	error_details    []string
	should_abort     bool
	is_vh            bool // Keep newlines
	is_clrf          bool
	tidx             int
	eofs             int
}

pub fn (l &Lexer) current_column() int {
	return l.pos - l.last_nl_pos
}

pub fn (mut l Lexer) inc_line_number() {
	l.last_nl_pos = l.text.len + 1
	if l.last_nl_pos > l.pos {
		l.last_nl_pos = l.pos
	}
	l.line_nr++
	if l.line_nr > l.nr_lines {
		l.nr_lines = l.line_nr
	}
}

pub fn (mut l Lexer) new_token(tok_kind token.Kind, lit string, len int) token.Token {
	cidx := l.tidx
	l.tidx++
	mut max_column := l.current_column() - len + 1
	if max_column < 1 {
		max_column = 1
	}

	return token.Token{
		kind: tok_kind
		lit: lit
		line_nr: l.line_nr + 1
		col: max_column
		pos: l.pos - len + 1
		len: len
		tidx: cidx
	}
}

fn (l &Lexer) new_eof_token() token.Token {
	return token.Token{
		kind: .eof
		lit: ''
		line_nr: l.line_nr + 1
		col: l.current_column()
		pos: l.pos
		len: 1
		tidx: l.tidx
	}
}

fn (mut l Lexer) new_multiline_token(tok_kind token.Kind, lit string, len int, start_line int) token.Token {
	cidx := l.tidx
	l.tidx++
	mut max_column := l.current_column() - len + 1
	if max_column < 1 {
		max_column = 1
	}
	return token.Token{
		kind: tok_kind
		lit: lit
		line_nr: start_line + 1
		col: max_column
		pos: l.pos - len + 1
		len: len
		tidx: cidx
	}
}

fn (mut l Lexer) end_of_file() token.Token {
	l.eofs++
	if l.eofs > 50 {
		l.line_nr--
		panic(
			'The end of file "${l.file_path}" has been reached 50 times. The lexer is probably stuck.\n' +
			'Look a the last few lines of code')
	}
	if l.pos != l.text.len && l.eofs == 1 {
		l.inc_line_number()
	}
	l.pos = l.text.len
	return l.new_eof_token()
}

pub fn (mut l Lexer) ident_name() string {
	start_pos := l.pos
	if l.pos + 1 < l.text.len && l.text[start_pos] == `-` && l.text[l.pos + 1] >= `0`
		&& l.text[l.pos + 1] <= `9` {
		l.error('identifiers cant start with a `-` followed by a number')
		return ''
	}
	for l.pos < l.text.len {
		c := l.text[l.pos]
		if (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || (c >= `0` && c <= `9`)
			|| c == `_` || c == `-` {
			l.pos++
			continue
		}
		break
	}
	name := l.text[start_pos..l.pos]
	l.pos--
	return name
}

pub fn (mut l Lexer) get_lit(start int, end int) string {
	return l.text[start..end]
}

fn (mut l Lexer) ident_number() string {
	mut has_wrong_digit := false
	mut first_wrong_digit_pos := 0
	// mut first_wrong_digit := `\0`
	start_pos := l.pos

	// scan integer part
	for l.pos < l.text.len {
		c := l.text[l.pos]
		if !c.is_digit() {
			if !c.is_letter() || c in [`e`, `E`] {
				break
			} else if !has_wrong_digit {
				has_wrong_digit = true
				first_wrong_digit_pos = l.pos
				// first_wrong_digit = c
			}
		}
		l.pos++
	}
	// scan fractional part
	if l.pos < l.text.len && l.text[l.pos] == `.` {
		l.pos++
		if l.pos < l.text.len {
			// 5.5
			if l.text[l.pos].is_digit() {
				for l.pos < l.text.len {
					c := l.text[l.pos]
					if !c.is_digit() {
						if !c.is_letter() || c in [`e`, `E`] {
							break
						} else if !has_wrong_digit {
							has_wrong_digit = true
							first_wrong_digit_pos = l.pos
							// first_wrong_digit = c
						}
					}
					l.pos++
				}
			} else if l.text[l.pos] in [`e`, `E`] {
				// 5.e5
			} else {
				// 5.
				mut symbol_length := 0
				for i := l.pos - 2; i > 0 && l.text[i - 1].is_digit(); i-- {
					symbol_length++
				}
				float_symbol := l.text[l.pos - 2 - symbol_length..l.pos - 1]
				l.warn('float literals should have a digit after the decimal point, e.g. `${float_symbol}.0`')
			}
		}
	}
	// scan exponential part
	mut has_exp := false
	if l.pos < l.text.len && l.text[l.pos] in [`e`, `E`] {
		has_exp = true
		l.pos++
		if l.pos < l.text.len && l.text[l.pos] in [`-`, `+`] {
			l.pos++
		}
		for l.pos < l.text.len {
			c := l.text[l.pos]
			if !c.is_digit() {
				if !c.is_letter() {
					break
				} else if !has_wrong_digit {
					has_wrong_digit = true
					first_wrong_digit_pos = l.pos
					// first_wrong_digit = c
				}
			}
			l.pos++
		}
	}

	if has_wrong_digit {
		// fix for 100em not being a number 100e + 'm'
		if l.text[first_wrong_digit_pos] == `m` && l.text[first_wrong_digit_pos - 1] in [`e`, `E`] {
			l.pos = first_wrong_digit_pos - 1
		} else {
			// error check: wrong digit
			l.pos = first_wrong_digit_pos // adjust error position
		}

		// if it's actually a wrong digit is handled in checker, because a unit is
		// normally followed by a number e.g. 100px
	} else if l.text[l.pos - 1] in [`e`, `E`] {
		// error check: 5e
		// don't handle error, because it could be a hex color ending with "e" e.g. #32383e;
	} else if l.pos < l.text.len && l.text[l.pos] == `.` {
		// error check: 1.23.4, 123.e+3.4
		if has_exp {
			l.error('exponential part should be integer')
		} else {
			l.error('too many decimal points in number')
		}
	}
	number := l.get_lit(start_pos, l.pos)
	l.pos--
	return number
}

pub fn (mut l Lexer) ident_string() string {
	lspos := token.Pos{
		line_nr: l.line_nr
		pos: l.pos
		col: l.pos - l.last_nl_pos
	}

	mut start := l.pos
	start_char := l.text[start]
	l.quote = start_char

	if start_char == l.quote {
		start++
	} else if start_char == lexer.b_lf {
		l.inc_line_number()
	}
	l.is_inside_string = false
	mut n_cr_chars := 0
	mut backslash_count := 0

	for {
		l.pos++
		if l.pos >= l.text.len {
			if lspos.line_nr + 1 < l.line_nr {
				l.add_error_detail_with_pos('literal started here', lspos)
			}
			l.error('unfinished string literal')
			break
		}
		c := l.text[l.pos]
		if c == lexer.backslash {
			backslash_count++
		}
		// end of string
		if c == l.quote && backslash_count % 2 == 0 {
			// handle '123\\' backslash at the end
			break
		}
		if c == lexer.b_cr {
			n_cr_chars++
		}
		if c == lexer.b_lf {
			l.inc_line_number()
		}
		if c != lexer.backslash {
			backslash_count = 0
		}
	}

	mut lit := ''
	mut end := l.pos
	if l.is_inside_string {
		end++
	}
	if start <= l.pos {
		lit = l.text[start..end]
	}
	return lit
}

fn (mut l Lexer) ident_comment() string {
	lspos := token.Pos{
		line_nr: l.line_nr
		pos: l.pos
		col: l.pos - l.last_nl_pos - 1
	}

	// skip "/*"
	start := l.pos + 2

	for {
		l.pos++
		if l.pos + 1 >= l.text.len {
			l.add_error_detail_with_pos('comment started here', lspos)
			l.warn('unfinished comment')
			break
		}

		c := l.text[l.pos]
		nextch := l.text[l.pos + 1]

		if c == lexer.b_lf {
			l.inc_line_number()
		} else if c == `*` && nextch == `/` {
			l.pos++
			break
		}
	}

	mut lit := ''
	// skip "*/"
	mut end := l.pos - 1
	if start <= l.pos {
		lit = l.text[start..end]
	}
	return lit
}

fn (mut l Lexer) ident_color() string {
	color_start := l.pos

	for {
		if l.pos >= l.text.len {
			break
		}

		c := l.text[l.pos]
		if !(((c >= `a` && c <= `f`) || (c >= `A` && c <= `F`)) || (c >= `0` && c <= `9`)) {
			break
		}
		l.pos++
	}

	color_len := l.pos - color_start
	// correct pos
	l.pos--
	if color_len in [3, 4, 6, 8] {
		return l.text[color_start..l.pos + 1]
	} else {
		// invalid hex color, correct position
		l.pos = color_start
		return ''
	}
}

fn (mut l Lexer) skip_whitespace() {
	for l.pos < l.text.len {
		c := l.text[l.pos]
		if c == 9 {
			// tabs are most common
			l.pos++
			continue
		}
		// space or non-printable ascii control characters
		if !(c == 32 || (c > 8 && c < 14) || c == 0x85 || c == 0xa0) {
			return
		}
		c_is_nl := c == lexer.b_cr || c == lexer.b_lf
		if c_is_nl && l.is_vh {
			return
		}
		if l.pos + 1 < l.text.len && c == lexer.b_cr && l.text[l.pos + 1] == lexer.b_lf {
			l.is_clrf = true
		}
		// count \r\n as one line
		if c_is_nl && !(l.pos > 0 && l.text[l.pos - 1] == lexer.b_cr && c == lexer.b_lf) {
			l.inc_line_number()
		}
		l.pos++
	}
}

pub fn (mut l Lexer) scan_remaining_text() {
	for {
		t := l.text_scan()
		l.all_tokens << t
		if t.kind == .eof || l.should_abort {
			break
		}
	}
}

@[direct_array_access]
pub fn (mut l Lexer) scan() token.Token {
	for {
		cidx := l.tidx
		l.tidx++
		if cidx >= l.all_tokens.len || l.should_abort {
			return l.end_of_file()
		}
		if l.all_tokens[cidx].kind == .comment {
			// TODO: parse comments?
			continue
		}
		return l.all_tokens[cidx]
	}
	return l.new_eof_token()
}

fn (mut l Lexer) text_scan() token.Token {
	for {
		if l.is_started {
			l.pos++
		} else {
			l.is_started = true
		}

		if l.pos >= l.text.len || l.should_abort {
			return l.end_of_file()
		}

		l.skip_whitespace()
		// end of file
		if l.pos >= l.text.len {
			return l.end_of_file()
		}
		// handle each char	
		c := l.text[l.pos]
		nextch := l.look_ahead(1)

		if is_name_char(c) {
			if !(c == `-` && !is_name_char(nextch)) {
				name := l.ident_name()
				return l.new_token(.name, name, name.len)
			}
		} else if c.is_digit() || (c == `.` && nextch.is_digit()) {
			// '123', ''.123'
			num := l.ident_number()
			return l.new_token(.number, num, num.len)
		}

		// all other tokens
		match c {
			`+` {
				return l.new_token(.plus, '', 1)
			}
			`-` {
				if nextch.is_digit() {
					l.pos++
					// -2
					num := l.ident_number()
					return l.new_token(.number, '-' + num, num.len + 1)
				}
				return l.new_token(.minus, '', 1)
			}
			`*` {
				return l.new_token(.mul, '', 1)
			}
			`/` {
				if nextch == `*` {
					start_line := l.line_nr
					ident_comment := l.ident_comment()
					return l.new_multiline_token(.comment, ident_comment, ident_comment.len,
						start_line)
				}
				return l.new_token(.div, '', 1)
			}
			lexer.single_quote, lexer.double_quote {
				start_line := l.line_nr
				mut ident_string := l.ident_string()

				// + 2 quotes
				mut tok := l.new_multiline_token(.string, ident_string, ident_string.len + 2,
					start_line)

				if c == lexer.single_quote {
					tok.meta = "'"
				} else {
					tok.meta = '"'
				}
				return tok
			}
			`.` {
				return l.new_token(.dot, '', 1)
			}
			`#` {
				return l.new_token(.hash, '', 1)
			}
			`@` {
				l.pos++
				at_name := l.ident_name()
				return l.new_token(.key_at, at_name, at_name.len)
			}
			`(` {
				return l.new_token(.lpar, '', 1)
			}
			`)` {
				return l.new_token(.rpar, '', 1)
			}
			`{` {
				return l.new_token(.lcbr, '', 1)
			}
			`}` {
				return l.new_token(.rcbr, '', 1)
			}
			`[` {
				return l.new_token(.lsbr, '', 1)
			}
			`]` {
				return l.new_token(.rsbr, '', 1)
			}
			`,` {
				return l.new_token(.comma, '', 1)
			}
			`:` {
				return l.new_token(.colon, '', 1)
			}
			`;` {
				return l.new_token(.semicolon, '', 1)
			}
			`>` {
				return l.new_token(.gt, '', 1)
			}
			`=` {
				return l.new_token(.equal, '', 1)
			}
			`^` {
				return l.new_token(.carrot, '', 1)
			}
			`$` {
				return l.new_token(.dollar, '', 1)
			}
			`!` {
				return l.new_token(.exclamation, '', 1)
			}
			`%` {
				return l.new_token(.percentage, '%', 1)
			}
			else {}
		}
	}
	return l.end_of_file()
}

fn (l &Lexer) look_ahead(n int) u8 {
	if l.pos + n < l.text.len {
		return l.text[l.pos + n]
	} else {
		return `\0`
	}
}

pub fn (mut l Lexer) current_pos() token.Pos {
	return token.Pos{
		line_nr: l.line_nr
		pos: l.pos
		col: l.current_column() - 1
	}
}

pub fn (mut l Lexer) add_error_detail(msg string) {
	l.error_details << msg
}

pub fn (mut l Lexer) add_error_detail_with_pos(msg string, pos token.Pos) {
	l.add_error_detail(errors.formatted_error('details:', msg, l.file_path, pos))
}

pub fn (mut l Lexer) get_details() string {
	mut details := ''
	if l.error_details.len > 0 {
		details = '\n' + l.error_details.join('\n')
		l.error_details = []
	}
	return details
}

pub fn (mut l Lexer) warn(msg string) {
	l.warn_with_pos(msg, l.current_pos())
}

pub fn (mut l Lexer) warn_with_pos(msg string, pos token.Pos) {
	details := l.get_details()
	errors.show_compiler_message('warning:',
		msg: msg
		details: details
		file_path: l.file_path
		pos: pos
	)
}

pub fn (mut l Lexer) error(msg string) {
	l.error_with_pos(msg, l.current_pos())
}

pub fn (mut l Lexer) error_with_pos(msg string, pos token.Pos) {
	details := l.get_details()
	errors.show_compiler_message('error:',
		msg: msg
		details: details
		file_path: l.file_path
		pos: pos
	)
}
