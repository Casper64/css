module parser

import css.ast
import css.errors
import css.lexer
import css.pref
import css.token
import os

const (
	double_quote = '"'
)

pub struct Parser {
	prefs &pref.Preferences
mut:
	file_name              string // "/css/main.css"
	tok                    token.Token
	prev_tok               token.Token
	peek_tok               token.Token
	inside_pseudo_selector bool
	parentheses_depth      int
	is_pseudo_element      bool
	is_important           bool
	// ast_imports // @import()
	error_details []string
	should_abort  bool // when t oo many warnings/errors occur should_abort becomes true and the parser should stop
pub mut:
	table       &ast.Table   = unsafe { nil }
	lexer       &lexer.Lexer = unsafe { nil }
	has_errored bool
}

// todo: add options?
pub fn Parser.new(prefs &pref.Preferences) &Parser {
	return &Parser{
		prefs: prefs
	}
}

// todo: same as above
fn (mut p Parser) init(filename string) {
}

[manualfree]
pub fn (mut p Parser) free_lexer() {
	unsafe {
		if p.lexer != 0 {
			p.lexer.free()
			p.lexer = &lexer.Lexer(nil)
		}
	}
}

pub fn (mut p Parser) set_path(file_path string) {
	// TODO: set current directory ?
	p.file_name = os.file_name(file_path)
}

pub fn (mut p Parser) next() {
	p.prev_tok = p.tok
	p.tok = p.peek_tok
	p.peek_tok = p.lexer.scan()
}

// for testing purposes
pub fn (mut p Parser) parse_text(raw_text string) &ast.StyleSheet {
	defer {
		unsafe { p.free_lexer() }
	}

	p.lexer = &lexer.Lexer{
		prefs: p.prefs
		all_tokens: []token.Token{cap: raw_text.len / 3}
		text: raw_text
	}
	p.lexer.scan_remaining_text()
	p.lexer.tidx = 0

	return p.parse()
}

pub fn (mut p Parser) parse_file(path string) &ast.StyleSheet {
	defer {
		unsafe { p.free_lexer() }
	}
	$if trace_parser ? {
		eprintln('> ${@MOD}.${@FN} path: ${path}')
	}

	// p.init(os.file_name(path))
	p.lexer = lexer.new_lexer_file(p.prefs, path) or { panic(err) }
	p.set_path(path)

	return p.parse()
}

pub fn (mut p Parser) parse() &ast.StyleSheet {
	// read first token and fill prev_token
	p.next()
	p.next()

	mut rules := []ast.RuleType{}

	mut imports := []ast.ImportRule{}

	for p.tok.kind == .key_at {
		if p.tok.kind == .eof {
			break
		}

		// only @charset and @layer can come before @import
		match p.tok.lit {
			// 'import' {
			// 	imports << p.parse_at_import()
			// }
			'charset' {
				rules << p.parse_at_charset() or {
					if err is ast.NodeError {
						p.error_with_pos(err.msg(), err.pos)
					}
					ast.AtRule{}
				}
			}
			'layer' {
				rules << p.parse_at_layer()
			}
			else {
				break
			}
		}
		p.next()
		if p.should_abort {
			break
		}
	}

	$if trace_parser ? {
		eprintln('> ${@MOD}.${@FN} done parsing import and got ${rules.len} other @rules')
	}

	for {
		if p.tok.kind == .eof {
			// TODO: check unused imports?
			break
		}
		rule := p.top_rule()
		rules << rule
		if p.should_abort {
			break
		}
	}

	// TODO (scope?) end position
	// TOOD: parse text???

	return &ast.StyleSheet{
		file_path: p.lexer.file_path
		imports: imports
		rules: rules
	}
}

pub fn (mut p Parser) top_rule() ast.RuleType {
	for {
		match p.tok.kind {
			.key_at {
				return p.at_decl()
			}
			.semicolon {
				p.next()
			}
			else {
				return p.block_decl()
			}
		}
	}
	// unreachable
	return ast.Empty{}
}

pub fn (mut p Parser) block_decl() ast.Rule {
	start_pos := p.tok.pos()

	mut selector_list := []ast.Node{}
	for {
		if p.tok.kind == .lcbr || p.tok.kind == .eof {
			if selector_list.len == 0 {
				p.error('expecting a css selector')
			}
			break
		}

		if selector := p.parse_selector() {
			if selector.children.len == 0 {
				p.error('expecting a css selector')
				p.next()
				continue
			} else {
				selector_list << selector
			}
		} else {
			for p.tok.kind != .comma && p.tok.kind != .lcbr {
				p.next()
			}
			if err is ast.NodeError {
				p.error_with_pos(err.msg(), err.pos)
				// TODO: switch to error node
				selector_list << ast.Raw{
					value: p.lexer.get_lit(err.pos.pos, p.tok.pos().pos)
					pos: err.pos.extend(p.tok.pos())
				}
			} else {
				p.error(err.msg())
			}
		}

		if p.tok.kind == .lcbr || p.tok.kind == .eof {
			break
		} else if p.tok.kind != .comma {
			// parse error!
			p.error('expecting a comma!')
		}
		p.next()
	}
	mut prelude := ast.SelectorList{
		pos: start_pos.extend(p.prev_tok.pos())
		children: selector_list
	}

	block_start := p.tok.pos()
	// skip '{'
	p.next()
	mut declarations := p.parse_declaration_block()

	mut rule := ast.Rule{
		pos: start_pos.extend(p.tok.pos())
		prelude: prelude
		block: ast.Block{
			pos: block_start.extend(p.tok.pos())
			declarations: declarations
		}
	}
	// skip '}'
	p.next()

	// for selector in prelude.children {
	// 	if selector is ast.Selector {
	// 		p.table.insert_declarations(selector, declarations)
	// 	}
	// }

	return rule
}

pub fn (mut p Parser) pseudo_decl() ast.Rule {
	return ast.Rule{}
}

pub fn (mut p Parser) recover_until(recover_token token.Kind) {
	for p.tok.kind != recover_token && p.tok.kind != .eof {
		p.next()
	}
}

pub fn (mut p Parser) recover_until_arr(recover_tokens ...token.Kind) {
	for p.tok.kind !in recover_tokens && p.tok.kind != .eof {
		p.next()
	}
}

// skip block finds the next '{' and continues until that brace is closed
pub fn (mut p Parser) skip_block() {
	mut brace_count := 0
	mut started := false
	for {
		if p.should_abort {
			return
		}
		match p.tok.kind {
			.eof {
				break
			}
			.lcbr {
				started = true
				brace_count++
			}
			.rcbr {
				if started == true {
					brace_count--
					if brace_count <= 0 {
						break
					}
				}
			}
			else {}
		}
		p.next()
	}
	p.next()
}

[params]
struct ParamsForUnexpected {
	got            string
	expecting      string
	prepend_msg    string
	additional_msg string
}

fn (mut p Parser) unexpected(params ParamsForUnexpected) ast.NodeError {
	return p.unexpected_with_pos(p.tok.pos(), params)
}

fn (mut p Parser) unexpected_with_pos(pos token.Pos, params ParamsForUnexpected) ast.NodeError {
	mut msg := if params.got != '' {
		'unexpected token ${params.got}'
	} else {
		'unexpected token ${p.tok}'
	}
	if params.expecting != '' {
		msg += ', expecting ${params.expecting}'
	}
	if params.prepend_msg != '' {
		msg = '${params.prepend_msg} ' + msg
	}
	if params.additional_msg != '' {
		msg += ', ${params.additional_msg}'
	}
	return p.error_with_pos(msg, pos)
}

pub fn (mut p Parser) warn(msg string) {
	p.warn_with_pos(msg, p.tok.pos())
}

pub fn (mut p Parser) get_details() string {
	mut details := ''
	if p.error_details.len > 0 {
		details = '\n' + p.error_details.join('\n')
		p.error_details = []
	}
	return details
}

pub fn (mut p Parser) warn_with_pos(msg string, pos token.Pos) {
	details := p.get_details()
	if !p.prefs.suppress_output {
		errors.show_compiler_message('warning:',
			msg: msg
			details: details
			file_path: p.lexer.file_path
			pos: pos
		)
	}
}

pub fn (mut p Parser) error(msg string) ast.NodeError {
	return p.error_with_pos(msg, p.tok.pos())
}

pub fn (mut p Parser) error_with_pos(msg string, pos token.Pos) ast.NodeError {
	p.has_errored = true
	details := p.get_details()

	if !p.prefs.suppress_output {
		errors.show_compiler_message('error:',
			msg: msg
			details: details
			file_path: p.lexer.file_path
			pos: pos
		)
	}

	return ast.NodeError{
		pos: pos
		msg: msg
	}
}
