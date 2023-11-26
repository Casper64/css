import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = &pref.Preferences{}

fn test_length() {
	rules := css_util.parse_stylesheet_from_text('.t { width: 100px; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'width': css.Value(css.DimensionValue(datatypes.Length{
			amount: 100
			unit: .px
		}))
	}
}

fn test_percentage() {
	rules := css_util.parse_stylesheet_from_text('.t { width: 110%; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'width': css.Value(css.DimensionValue(datatypes.Percentage(1.1)))
	}
}

fn test_zero() {
	rules := css_util.parse_stylesheet_from_text('.t { width: 0; top: 0; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'width': css.Value(css.DimensionValue(0.0))
		'top':   css.Value(css.DimensionValue(0.0))
	}
}
