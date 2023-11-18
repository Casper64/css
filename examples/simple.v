module main

import css
import css.util as css_util

fn main() {
	// get all rules from `simple.css`
	mut rules := css_util.parse_stylesheet('simple.css')!

	// the selector representation for the element <p class="test" id="what">
	mut selector := [css.Selector(css.Type('p')), css.Class('test'), css.Id('what')]

	// filter all rules that match `selector`
	matching_rules := rules.filter(fn [selector] (rule css.Rule) bool {
		return rule.matches(selector)
	})

	// build a map of styles from the matching rules
	styles := matching_rules.get_styles()

	println('final styles for selector "${selector}":')
	println(styles)
}
