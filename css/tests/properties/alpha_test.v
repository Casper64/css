import css
import css.pref
import css.util as css_util

const preferences = pref.Preferences{}

fn test_alpha_value_percentage() {
	rules := css_util.parse_stylesheet_from_text('.t { opacity: 90%; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'opacity': css.Value(css.AlphaValue(0.9))
	}
}

fn test_alpha_value_number() {
	rules := css_util.parse_stylesheet_from_text('.t { opacity: 0.4; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'opacity': css.Value(css.AlphaValue(0.4))
	}
}
