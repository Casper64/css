module css

import css.ast
import css.datatypes

pub type ColorValue = datatypes.Color | string

// value between 0.0 and 1.0
pub type AlphaValue = Keyword | f64
pub type DimensionValue = Keyword
	| datatypes.CalcSum
	| datatypes.Length
	| datatypes.Percentage
	| f64

pub type Keyword = string

pub type Image = Gradient | Keyword | Url

pub type Value = AlphaValue
	| Background
	| Border
	| BorderColors
	| BorderStyles
	| ColorValue
	| DimensionValue
	| Gradient
	| Image
	| Keyword
	| MarginPadding
	| Overflow
	| Shadow
	| Text
	| TextCombineUpright
	| TextEllipsis
	| TextOverflow
	| string

pub struct Attribute {
pub mut:
	name    string
	matcher ast.AttributeMatchType
	value   ?string
}

pub fn (a Attribute) str() string {
	mut s := '[${a.name}'
	if v := a.value {
		s += match a.matcher {
			.@none { '' }
			.exact { '="${v}"' }
			.contains { '*="${v}"' }
			.starts_with { '^="${v}"' }
			.ends_with { '$="${v}"' }
		}
	}
	s += ']'
	return s
}

pub fn (a Attribute) == (b Attribute) bool {
	if a.name != b.name {
		return false
	}

	if va := a.value {
		vb := b.value or { return false }

		return match a.matcher {
			.@none {
				// should never reach this
				false
			}
			.exact {
				va == vb
			}
			.contains {
				va.contains(vb)
			}
			.starts_with {
				va.starts_with(vb)
			}
			.ends_with {
				va.ends_with(vb)
			}
		}
	}
	// a[href]
	return true
}

pub type Class = string

pub fn (c Class) str() string {
	return '.' + c
}

pub type Combinator = string

pub fn (cm Combinator) str() string {
	if cm != ' ' {
		return ' ' + cm + ' '
	} else {
		return ' '
	}
}

pub type Id = string

pub fn (id Id) str() string {
	return '#' + id
}

pub type Type = string

pub fn (typ Type) str() string {
	return typ
}

pub struct PseudoClass {
pub mut:
	name     string
	children []Selector
}

pub fn (pc PseudoClass) str() string {
	mut s := ':${pc.name}'
	if pc.children.len > 0 {
		s += '(${pc.children})'
	}
	return s
}

pub struct PseudoElement {
pub mut:
	name     string
	children []Selector
}

pub fn (pe PseudoElement) str() string {
	mut s := '::${pe.name}'
	if pe.children.len > 0 {
		s += '(${pe.children})'
	}
	return s
}

pub type Selector = Attribute | Class | Combinator | Id | PseudoClass | PseudoElement | Type

pub fn (selectors []Selector) str() string {
	mut res := ''
	for s in selectors {
		res += match s {
			Class { s.str() }
			Id { s.str() }
			Type { s.str() }
			Combinator { s.str() }
			PseudoClass { s.str() }
			PseudoElement { s.str() }
			Attribute { s.str() }
		}
	}
	return res
}

// check if `other_selectors` is a subset of `current_selectors`
// matches the part of `current_selectors` after the last Combinator
pub fn (current_selectors []Selector) matches(other_selectors []Selector) bool {
	// last_selectors are all selectors that come after the last Combinator
	// in `current_selectors`
	mut last_selectors := []Selector{}
	for s in current_selectors {
		if s is Combinator {
			last_selectors.clear()
		} else {
			last_selectors << s
		}
	}

	for s in last_selectors {
		match s {
			PseudoClass {
				if s.name == 'not' {
					if s.children.matches(other_selectors) {
						return false
					}
				}
				// TODO: :is
			}
			PseudoElement {
				// pseudo elements should be matched in combination with a DOM
				return true
			}
			Attribute {
				for a in other_selectors {
					if a is Attribute && s != a {
						return false
					}
				}
			}
			else {
				if s !in other_selectors {
					return false
				}
			}
		}
	}
	return true
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

pub fn Specificity.from_selectors(selectors []Selector) Specificity {
	mut s := Specificity{}

	for current_selector in selectors {
		match current_selector {
			Id {
				s.col1++
			}
			Attribute, Class {
				s.col2++
			}
			PseudoClass {
				if current_selector.name == 'where' {
					// :where doesn't count for specificity, same applies for its children
					continue
				} else if current_selector.name !in ['is', 'has', 'not'] {
					// :is, :has and :not don't count for specificity, but their children do
					s.col2++
				}
				s += Specificity.from_selectors(current_selector.children)
			}
			Type {
				if current_selector != '*' {
					// the universal selector does not count for specificity
					s.col3++
				}
			}
			PseudoElement {
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

pub struct RawValue {
pub mut:
	value     Value
	important bool
}

// Rule represents a css rule with only a single selector
pub struct Rule {
pub mut:
	specificity  Specificity
	selectors    []Selector
	declarations map[string]RawValue
}

@[inline]
pub fn (r Rule) matches(selectors []Selector) bool {
	return r.selectors.matches(selectors)
}

pub fn (rules []Rule) get_styles() map[string]Value {
	// TODO: merge grouped properties together e.g. `background` gets split
	// into 'background-color', 'background-width' etc.
	// OR combine them from `background-color` to `background` only
	mut styles := map[string]Value{}
	mut importants := map[string]bool{}

	// TODO: reduce iterations
	for rule in rules {
		for property, value in rule.declarations {
			if !value.important && importants[property] == false {
				set_grouped(property, value.value, mut styles)
			} else if value.important {
				set_grouped(property, value.value, mut styles)
				importants[property] = true
			}
		}
	}

	return styles
}

pub type TextCombineUprightDigits = int
pub type TextCombineUpright = Keyword | TextCombineUprightDigits

// text-overflow: ellipsis "[..]"; will become `css.TextOverflow(css.TextEllipsis('[..]'))`
pub type TextEllipsis = string
pub type TextOverflow = Keyword | TextEllipsis

pub type ShadowValue = Keyword | Shadow

pub type BorderLineStyle = Keyword | datatypes.LineStyle
