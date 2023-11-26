import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = &pref.Preferences{}

fn test_rgb() {
	rules := css_util.parse_stylesheet_from_text('.t { color: rgb(10 20 30); }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'color': css.Value(css.ColorValue(datatypes.Color{
			r: 10
			g: 20
			b: 30
			a: 255
		}))
	}
}

fn test_rgba() {
	rules := css_util.parse_stylesheet_from_text('.t { color: rgb(10 20 30 / 20%); }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'color': css.Value(css.ColorValue(datatypes.Color{
			r: 10
			g: 20
			b: 30
			a: u8(255 * 0.2)
		}))
	}
}
