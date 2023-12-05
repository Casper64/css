module ast

pub struct RuleNode {
pub:
	selector    Selector
	specificity Specificity
pub mut:
	declaration_idx int
}

@[heap; minify]
pub struct Table {
pub mut:
	// front = least specific, back = most specific
	rules            []RuleNode
	raw_declarations [][]Node
	// at_rules []AtRuleNode
}

pub fn (mut t Table) insert_rule(selector_list []Node, declarations []Node) {
	for selector in selector_list {
		if selector is Selector {
			specificity := Specificity.from_selectors(selector.children)
			node := RuleNode{
				selector: selector
				specificity: specificity
				declaration_idx: t.raw_declarations.len
			}

			t.rules << node
		}
	}

	t.raw_declarations << [declarations]
}

pub fn (mut t Table) sort_rules() {
	t.rules.sort(|a, b| a.specificity <= b.specificity)
}

// Specificity represents CSS specificity
// https://developer.mozilla.org/en-US/docs/Web/CSS/Specificity
pub struct Specificity {
pub mut:
	col1 int
	col2 int
	col3 int
}

pub fn (s &Specificity) str() string {
	return '${s.col1}-${s.col2}-${s.col3}'
}

pub fn Specificity.from_selectors(selectors []Node) Specificity {
	mut s := Specificity{}

	for current_selector in selectors {
		match current_selector {
			IdSelector {
				s.col1++
			}
			AttributeSelector, ClassSelector {
				s.col2++
			}
			PseudoClassSelector {
				if current_selector.name == 'where' {
					// :where doesn't count for specificity, same applies for its children
					continue
				} else if current_selector.name !in ['is', 'has', 'not'] {
					// :is, :has and :not don't count for specificity, but their children do
					s.col2++
				}
				s += Specificity.from_selectors(current_selector.children)
			}
			TypeSelector {
				if current_selector.name != '*' {
					// the universal selector does not count for specificity
					s.col3++
				}
			}
			PseudoElementSelector {
				s.col3++
				s += Specificity.from_selectors(current_selector.children)
			}
			else {}
		}
	}

	return s
}

fn (a Specificity) == (b Specificity) bool {
	return a.col1 == b.col1 && a.col2 == b.col2 && a.col3 == b.col3
}

fn (a Specificity) < (b Specificity) bool {
	if a.col1 < b.col1 {
		return true
	} else if a.col1 == b.col1 {
		if a.col2 < b.col2 {
			return true
		} else if a.col2 == b.col2 {
			return a.col3 < b.col3
		}
	}
	return false
}

fn (a Specificity) + (b Specificity) Specificity {
	return Specificity{
		col1: a.col1 + b.col1
		col2: a.col2 + b.col2
		col3: a.col3 + b.col3
	}
}

fn (a Specificity) - (b Specificity) Specificity {
	return Specificity{
		col1: a.col1 - b.col1
		col2: a.col2 - b.col2
		col3: a.col3 - b.col3
	}
}
