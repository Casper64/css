import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = pref.Preferences{}

fn test_color_name() {
	rules := css_util.parse_stylesheet_from_text('.t { color: red; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'color': css.Value(css.ColorValue('red'))
	}
}

fn test_color_hex() {
	rules := css_util.parse_stylesheet_from_text('.t { color: #ffffff; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'color': css.Value(css.ColorValue(datatypes.Color{
			r: 255
			g: 255
			b: 255
			a: 255
		}))
	}
}
