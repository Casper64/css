import css
import css.datatypes
import css.pref
import css.util as css_util

const (
	preferences = &pref.Preferences{}
)

// -webkit- and -moz- should end up in the styles map, 
// but be parsed as if the browser prefix isn't present.

fn test_webkit() {
	rules := css_util.parse_stylesheet_from_text('.t { -webkit-color: red; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'-webkit-color': css.Value(css.ColorValue('red'))
	}
}

fn test_moz() {
	rules := css_util.parse_stylesheet_from_text('.t { -moz-color: red; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'-moz-color': css.Value(css.ColorValue('red'))
	}
}