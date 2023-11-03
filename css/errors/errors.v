module errors

// ACKNOWLEDGEMENT: this file is almost a straight copy paste from v/vlib/v/util/errors.v
import css.token
import os
import strings
import term
import v.mathutil as mu

// error_context_before - how many lines of source context to print before the pointer line
// error_context_after - ^^^ same, but after
const (
	error_context_before = 2
	error_context_after  = 2
)

[params]
pub struct CompilerMessage {
	msg       string
	details   string
	file_path string
	pos       token.Pos
}

const normalised_workdir = os.wd_at_startup.replace('\\', '/') + '/'

// NOTE: path_styled_for_error_messages will *always* use `/` in the error paths, no matter the OS,
// to ensure stable compiler error output in the tests.
pub fn path_styled_for_error_messages(path string) string {
	mut rpath := os.real_path(path)
	rpath = rpath.replace('\\', '/')

	if rpath.starts_with(errors.normalised_workdir) {
		rpath = rpath.replace_once(errors.normalised_workdir, '')
	}
	return rpath
}

pub fn formatted_error(kind string, omsg string, filepath string, pos token.Pos) string {
	emsg := omsg.replace('main.', '')
	path := path_styled_for_error_messages(filepath)
	position := if filepath.len > 0 {
		'${path}:${pos.line_nr + 1}:${mu.max(1, pos.col + 1)}:'
	} else {
		''
	}

	final_position := bold(position)
	final_kind := bold(color(kind, kind))
	final_msg := emsg

	// skip context for .min.css files
	if filepath.ends_with('.min.css') {
		return '${final_position} ${final_kind} ${final_msg}'.trim_space()
	}

	scontext := source_file_context(kind, filepath, pos).join('\n')
	final_context := if scontext.len > 0 { '\n${scontext}' } else { '' }

	return '${final_position} ${final_kind} ${final_msg}${final_context}'.trim_space()
}

pub fn show_compiler_message(kind string, err CompilerMessage) {
	eprintln(formatted_error(kind, err.msg, err.file_path, err.pos))
	if err.details.len != 0 {
		eprintln(err.details)
	}
}

pub fn bold(msg string) string {
	// if !errors.emanager.support_color {
	// 	return msg
	// }
	return term.bold(msg)
}

pub fn color(kind string, msg string) string {
	// if !errors.emanager.support_color {
	// 	return msg
	// }
	if kind.contains('error') {
		return term.red(msg)
	}
	if kind.contains('notice') {
		return term.yellow(msg)
	}
	if kind.contains('details') {
		return term.bright_blue(msg)
	}
	return term.magenta(msg)
}

// set_source_for_path should be called for every file, over which you want to use errors.formatted_error
pub fn set_source_for_path(path string, source string) []string {
	lines := source.split_into_lines()
	return lines
}

pub fn file2sourcelines(path string) []string {
	source := os.read_file(path) or { '' }
	res := set_source_for_path(path, source)
	return res
}

pub fn source_file_context(kind string, filepath string, pos token.Pos) []string {
	mut clines := []string{}
	source_lines := unsafe { file2sourcelines(filepath) }
	if source_lines.len == 0 {
		return clines
	}
	bline := mu.max(0, pos.line_nr - errors.error_context_before)
	aline := mu.max(0, mu.min(source_lines.len - 1, pos.line_nr + errors.error_context_after))
	tab_spaces := '    '
	for iline := bline; iline <= aline; iline++ {
		sline := source_lines[iline]
		start_column := mu.max(0, mu.min(pos.col, sline.len))
		end_column := mu.max(0, mu.min(pos.col + mu.max(0, pos.len), sline.len))
		cline := if iline == pos.line_nr {
			sline[..start_column] + color(kind, sline[start_column..end_column]) +
				sline[end_column..]
		} else {
			sline
		}
		clines << '${iline + 1:5d} | ' + cline.replace('\t', tab_spaces)
		//
		if iline == pos.line_nr {
			// The pointerline should have the same spaces/tabs as the offending
			// line, so that it prints the ^ character exactly on the *same spot*
			// where it is needed. That is the reason we can not just
			// use strings.repeat(` `, col) to form it.
			mut pointerline_builder := strings.new_builder(sline.len)
			for i := 0; i < start_column; {
				if sline[i].is_space() {
					pointerline_builder.write_u8(sline[i])
					i++
				} else {
					char_len := utf8_char_len(sline[i])
					spaces := ' '.repeat(utf8_str_visible_length(sline[i..i + char_len]))
					pointerline_builder.write_string(spaces)
					i += char_len
				}
			}
			underline_len := utf8_str_visible_length(sline[start_column..end_column])
			underline := if underline_len > 1 { '~'.repeat(underline_len) } else { '^' }
			pointerline_builder.write_string(bold(color(kind, underline)))
			clines << '      | ' + pointerline_builder.str().replace('\t', tab_spaces)
		}
	}
	return clines
}

pub fn did_you_mean(values []string) string {
	options := values.map(|v| term.bright_blue('`${v}`')).join(', ')
	return 'Did you mean ${options}?'
}
