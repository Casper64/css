module ast

pub struct RuleNode {
pub:
	selectors []Node
	// specificity  Specificity
	declarations []Node
}

@[heap; minify]
pub struct Table {
pub mut:
	// front = least specific, back = most specific
	rules []RuleNode
	// at_rules []AtRuleNode
}

pub fn (mut t Table) insert_declarations(selector Selector, declarations []Node) {
	// specificity := Specificity.from_selector(selector)
	// node := RuleNode{
	// 	selectors: selector.children
	// 	specificity: specificity
	// 	declarations: declarations
	// }

	// t.rules << node
}

pub fn (mut t Table) sort_rules() {
	// t.rules.sort(|a, b| a.specificity <= b.specificity)
}
