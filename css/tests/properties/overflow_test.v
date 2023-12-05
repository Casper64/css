import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = &pref.Preferences{}

fn test_single_keyword() {
	rules := css_util.parse_stylesheet_from_text('.t { overflow: hidden; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'overflow': css.Overflow{
			overflow_x: 'hidden'
			overflow_y: 'hidden'
		}
	}
}

fn test_individual_keyword() {
	rules := css_util.parse_stylesheet_from_text('.t { overflow-x: hidden; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'overflow': css.Overflow{
			overflow_x: 'hidden'
		}
	}
}

fn test_merged() {
	rules := css_util.parse_stylesheet_from_text('.t { overflow-x: hidden; overflow-y: visible; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'overflow': css.Overflow{
			overflow_x: 'hidden'
			overflow_y: 'visible'
		}
	}
}
