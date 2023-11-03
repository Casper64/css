module token

[minify]
pub struct Token {
pub:
	kind    Kind   // the token number/enum; for quick comparisons
	lit     string // literal representation of the token
	line_nr int    // the line number in the source where the token occurred
	col     int    // the column in the source where the token occurred
	// name_idx int // name table index for O(1) lookup
	pos  int // the position of the token in scanner text
	len  int // length of the literal
	tidx int // the index of the token
pub mut:
	// metadata used for strings to indicate whether the token has single or double quotes
	meta string
}

pub fn (t &Token) str() string {
	if t.lit.len != 0 {
		return '${t.kind} = "${t.lit}"'
	} else {
		return t.kind.str()
	}
}

pub enum Kind {
	unkown
	name
	eof
	number // 123
	string // 'foo'
	plus // +
	minus // -
	mul // *
	div // /
	gt // >
	comma // ,
	semicolon // ;
	dot // .
	hash // #
	colon // :
	key_at // @
	lcbr // {
	rcbr // }
	lpar // (
	rpar // )
	lsbr // [
	rsbr // ]
	comment
	equal // =
	carrot // ^
	dollar // $
	exclamation // !
	percentage // %
	color // ffffff
}
