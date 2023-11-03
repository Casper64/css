import css

fn test_selector() {
	mut s1 := []css.Selector{}
	mut s2 := []css.Selector{}

	s1 = [css.Class('test')]
	s2 = [css.Id('what'), css.Class('test')]

	// s1 is a subset of s2
	assert s1.matches(s2) == true
	// s2 is not a subset of s1
	assert s2.matches(s1) == false
}

fn test_different_types_same_values() {
	mut s1 := []css.Selector{}
	mut s2 := []css.Selector{}

	s1 = [css.Class('test')]
	s2 = [css.Id('test')]

	assert s1.matches(s2) == false
	assert s2.matches(s1) == false
}

fn test_skipping_combinators() {
	mut s1 := []css.Selector{}
	mut s2 := []css.Selector{}

	s1 = [css.Class('test'), css.Combinator('>'), css.Id('what')]
	s2 = [css.Class('test')]

	assert s1.matches(s2) == false
}

fn test_attribute() {
	assert css.Attribute{
		name: 'href'
	} != css.Attribute{
		name: 'id'
	}

	assert css.Attribute{
		name: 'href'
		matcher: .exact
		value: '#test'
	} != css.Attribute{
		name: 'href'
	}

	assert css.Attribute{
		name: 'href'
		matcher: .exact
		value: '#test'
	} == css.Attribute{
		name: 'href'
		value: '#test'
	}

	assert css.Attribute{
		name: 'href'
		matcher: .contains
		value: '#test'
	} == css.Attribute{
		name: 'href'
		value: 'test'
	}

	assert css.Attribute{
		name: 'href'
		matcher: .starts_with
		value: '#test'
	} == css.Attribute{
		name: 'href'
		value: '#te'
	}

	assert css.Attribute{
		name: 'href'
		matcher: .ends_with
		value: '#test'
	} == css.Attribute{
		name: 'href'
		value: 'st'
	}

	mut s1 := []css.Selector{}
	mut s2 := []css.Selector{}

	// [href="#test"] {}
	s1 = [css.Attribute{
		name: 'href'
		matcher: .exact
		value: '#test'
	}]
	// <a href="#test"></a>
	s2 = [css.Type('a'), css.Attribute{
		name: 'href'
		value: '#test'
	}]

	assert s1.matches(s2) == true

	// [data-test="wot"] {}
	s1 = [css.Attribute{
		name: 'data-test'
		matcher: .exact
		value: 'wot'
	}]
	// <a data-test></a>
	s2 = [css.Type('a'), css.Attribute{
		name: 'data-test'
	}]
	assert s1.matches(s2) == false
}

fn test_not() {
	mut s1 := []css.Selector{}
	mut s2 := []css.Selector{}

	// :not(.c), .a.b.c
	s1 = [css.PseudoClass{
		name: 'not'
		children: [css.Class('c')]
	}]
	s2 = [css.Class('a'), css.Class('b'), css.Class('c')]

	assert s1.matches(s2) == false

	s2.pop()
	// :not(.c), .a.b
	assert s1.matches(s2) == true
}
