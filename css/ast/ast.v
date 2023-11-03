module ast

// implementing ast from https://github.com/csstree/csstree/blob/master/docs/ast.md
// following the mdn specs for css https://developer.mozilla.org/en-US/docs/Web/CSS
import css.token

// empty struct
pub struct Empty {}

// a css file
[heap]
pub struct StyleSheet {
pub:
	file_path string
pub mut:
	imports []ImportRule
	rules   []RuleType
}

pub struct Rule {
pub:
	pos token.Pos
pub mut:
	prelude Prelude
	block   Block
}

pub struct AtRule {
pub:
	pos token.Pos
pub mut:
	typ      AtType
	prelude  []Node
	children []Node
}

pub struct ImportRule {
pub:
	pos token.Pos
pub mut:
	typ   ImportType
	path  string
	layer ?string
	// supports []SupportRule
	media_query_list ?MediaQueryList
}

pub struct KeyframesRule {
pub:
	pos token.Pos
pub mut:
	percentage   string
	declarations []Node
}

pub struct Block {
pub:
	pos token.Pos
pub mut:
	declarations []Node
}

pub struct Declaration {
pub:
	pos token.Pos
pub mut:
	property  string
	important bool
	value     Value
}

pub struct Function {
pub:
	pos token.Pos
pub mut:
	name     string
	children []Node
}

pub struct Dimension {
pub:
	pos token.Pos
pub mut:
	value string
	unit  string
}

pub struct Hash {
pub:
	pos token.Pos
pub mut:
	value string
}

pub struct Ident {
pub:
	pos token.Pos
pub mut:
	name string
}

pub struct Number {
pub:
	pos token.Pos
pub mut:
	value string
}

pub struct Operator {
pub:
	pos token.Pos
pub mut:
	kind OperatorKind
}

pub fn (op Operator) == (other Operator) bool {
	return op.kind == other.kind
}

pub struct Parentheses {
pub:
	pos token.Pos
pub mut:
	children []Node
}

pub struct MediaFeature {
pub:
	pos token.Pos
pub mut:
	name  string
	value ?Node
}

pub struct MediaQuery {
pub:
	pos token.Pos
pub mut:
	children []Node
}

pub struct MediaQueryList {
pub:
	pos token.Pos
pub mut:
	children []MediaQuery
}

// Raw is used for some functions like `url()` or anything that can't be properly parsed
pub struct Raw {
pub:
	pos token.Pos
pub mut:
	value string
}

pub struct Value {
pub:
	pos token.Pos
pub mut:
	children []Node
}

pub struct SelectorList {
pub:
	pos token.Pos
pub mut:
	children []Node
}

pub struct Selector {
pub:
	pos token.Pos
pub mut:
	children []Node
}

// matches tests if the selectors in `s1` match the selectors in `nodes`:
// it checks if s1 is a subset of nodes
// the selectors children will be split on combinators and onl the last part is matched:
// .test > .other#id will only try to match for .other#id
pub fn (selector Selector) matches(other_selectors []Node) bool {
	mut last_nodes := []Node{}
	for n in selector.children {
		if n is Combinator {
			last_nodes.clear()
		} else {
			last_nodes << n
		}
	}

	for sub_s1 in last_nodes {
		if sub_s1 !in other_selectors {
			return false
		}
		// match sub_s1 {
		// 	IdSelector, ClassSelector, TypeSelector {
		// 		if sub_s1 !in s2.children {
		// 			return false
		// 		}
		// 	}
		// 	else {
		// 		return false
		// 	}
		// }
	}
	return true
}

pub struct ClassSelector {
pub:
	pos token.Pos
pub mut:
	name string
}

pub struct TypeSelector {
pub:
	pos token.Pos
pub mut:
	name string
}

pub struct IdSelector {
pub:
	pos token.Pos
pub mut:
	name string
}

pub struct Combinator {
pub:
	pos token.Pos
pub mut:
	kind string
}

pub struct PseudoClassSelector {
pub:
	pos token.Pos
pub mut:
	name     string
	children []Node
}

pub struct PseudoElementSelector {
pub:
	pos token.Pos
pub mut:
	name     string
	children []Node
}

pub struct AttributeSelector {
pub:
	pos token.Pos
pub mut:
	name    Ident
	matcher AttributeMatchType
	value   ?String
}

pub struct String {
pub:
	pos token.Pos
pub mut:
	value string
}

pub type Node = AtRule
	| AttributeSelector
	| Block
	| ClassSelector
	| Combinator
	| Declaration
	| Dimension
	| Empty
	| Function
	| Hash
	| IdSelector
	| Ident
	| ImportRule
	| KeyframesRule
	| MediaFeature
	| MediaQuery
	| MediaQueryList
	| NodeError
	| Number
	| Operator
	| Parentheses
	| Prelude
	| PseudoClassSelector
	| PseudoElementSelector
	| PseudoSelector
	| Raw
	| Rule
	| RuleType
	| Selector
	| SelectorList
	| String
	| StyleSheet
	| TypeSelector
	| Value

pub fn (node Node) children() []Node {
	return match node {
		AtRule {
			mut children := []Node{}
			children << node.prelude
			children << node.children
			children
		}
		Rule {
			mut children := []Node{}
			children << Node(node.prelude)
			children << node.block
			children
		}
		ImportRule {
			if l := node.media_query_list {
				[Node(l)]
			} else {
				[]Node{}
			}
		}
		Block, KeyframesRule {
			node.declarations
		}
		Declaration {
			[Node(node.value)]
		}
		Function, Parentheses, MediaQuery, Value, SelectorList, Selector, PseudoClassSelector,
		PseudoElementSelector {
			node.children
		}
		MediaFeature {
			if f := node.value {
				return [f]
			} else {
				[]Node{}
			}
		}
		MediaQueryList {
			mut children := []Node{}
			children << node.children
			children
		}
		else {
			[]Node{}
		}
	}
}

pub fn (node Node) pos() token.Pos {
	return match node {
		StyleSheet, Empty {
			token.Pos{}
		}
		Rule, AtRule, ImportRule, KeyframesRule, Block, Declaration, Function, Dimension, Hash,
		Ident, Number, Operator, Parentheses, MediaFeature, MediaQuery, MediaQueryList, Raw, Value,
		SelectorList, Selector, ClassSelector, TypeSelector, IdSelector, Combinator,
		PseudoClassSelector, PseudoElementSelector, AttributeSelector, String {
			node.pos
		}
		else {
			token.Pos{}
		}
	}
}
