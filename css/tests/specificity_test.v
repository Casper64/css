import css

fn test_specificity() {
	s := css.Specificity.from_selectors([
		css.Id(''),
		css.Class(''),
		css.Type(''),
		css.Combinator(''),
		css.Id(''),
		css.Attribute{},
		css.Attribute{},
		// should be ignored
		css.Type('*'),
	])

	assert s.str() == '2-3-1'
}

fn test_pseudo_selectors() {
	s := css.Specificity.from_selectors([
		// should be ignored
		css.PseudoClass{
			name: 'where'
			children: [css.Id('')]
		},
		css.PseudoClass{
			name: 'is'
		},
		css.PseudoClass{
			name: 'has'
		},
		// should not add to specificity, but children should count
		css.PseudoClass{
			name: 'not'
			children: [css.Id('')]
		},
		css.PseudoElement{
			name: 'what'
			children: [css.Type('')]
		},
	])

	assert s.str() == '1-0-2'
}

fn test_comparison() {
	// 1-2-0
	mut s1 := css.Specificity.from_selectors([css.Id(''), css.Class(''), css.Class('')])

	// 1-2-1
	mut s2 := css.Specificity.from_selectors([css.Id(''), css.Class(''), css.Class(''), css.Type('')])

	// 1-2-1 > 1-2-0
	assert s2 > s1

	// s1 + 1-0-0 = 2-2-0
	s1 += css.Specificity.from_selectors([css.Id('')])

	// 2-2-0 > 1-2-0from_selector({
	assert s1 > s2

	// s1 + 0-0-1 = 2-2-1
	s1 += css.Specificity.from_selectors([css.Type('')])

	// s2 + 1-0-0 = 2-2-1
	s2 += css.Specificity.from_selectors([css.Id('')])

	// 2-2-1 = 2-2-1
	assert s1 == s2
}

fn test_comparison_inverted() {
	// 0-2-0
	mut s1 := css.Specificity.from_selectors([css.Class(''), css.Class('')])

	// 0-1-2
	mut s2 := css.Specificity.from_selectors([css.Class(''), css.Type(''), css.Type('')])

	assert s1 > s2
}
