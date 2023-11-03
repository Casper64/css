module ast

import css.token

pub type RuleType = AtRule | Empty | KeyframesRule | Rule

pub type Prelude = Raw | SelectorList

pub enum AtType {
	unkown
	charset
	container
	counter_style
	font_face
	@import
	keyframes
	layer
	media
}

pub struct NodeError {
pub:
	pos  token.Pos
	msg  string
	code int
}

pub fn (n NodeError) msg() string {
	return n.msg
}

pub fn (n NodeError) code() int {
	return n.code
}

pub type PseudoSelector = PseudoClassSelector | PseudoElementSelector | Raw

pub enum AttributeMatchType {
	@none
	exact // =
	contains // *=
	starts_with // ^=
	ends_with // $=
}

pub enum OperatorKind {
	plus // +
	min // -
	mul // *
	div // /
	comma // ,
}

pub enum ImportType {
	url
	path
}
