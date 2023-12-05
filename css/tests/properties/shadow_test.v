import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = &pref.Preferences{}

fn test_shadow_keyword() {
	rules := css_util.parse_stylesheet_from_text('.t { box-shadow: none; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'box-shadow': css.ShadowValue(css.Keyword('none'))
	}
}

fn test_two_lengths() {
	rules := css_util.parse_stylesheet_from_text('.t { box-shadow: 2px 4px red; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'box-shadow': css.ShadowValue(css.Shadow{
			offset_x: datatypes.Length{
				amount: 2
				unit: .px
			}
			offset_y: datatypes.Length{
				amount: 4
				unit: .px
			}
			color: 'red'
		})
	}
}

fn test_three_lengths() {
	rules := css_util.parse_stylesheet_from_text('.t { box-shadow: 2px 4px .6px red; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'box-shadow': css.ShadowValue(css.Shadow{
			offset_x: datatypes.Length{
				amount: 2
				unit: .px
			}
			offset_y: datatypes.Length{
				amount: 4
				unit: .px
			}
			blur_radius: datatypes.Length{
				amount: 0.6
				unit: .px
			}
			color: 'red'
		})
	}
}

fn test_four_lengths() {
	rules := css_util.parse_stylesheet_from_text('.t { box-shadow: 2px 4px .6px 1em red; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'box-shadow': css.ShadowValue(css.Shadow{
			offset_x: datatypes.Length{
				amount: 2
				unit: .px
			}
			offset_y: datatypes.Length{
				amount: 4
				unit: .px
			}
			blur_radius: datatypes.Length{
				amount: 0.6
				unit: .px
			}
			spread_radius: datatypes.Length{
				amount: 1
				unit: .em
			}
			color: 'red'
		})
	}
}

fn test_inset() {
	rules := css_util.parse_stylesheet_from_text('.t { box-shadow: inset 2px 4px red; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'box-shadow': css.ShadowValue(css.Shadow{
			inset: true
			offset_x: datatypes.Length{
				amount: 2
				unit: .px
			}
			offset_y: datatypes.Length{
				amount: 4
				unit: .px
			}
			color: 'red'
		})
	}
}

fn test_all() {
	rules := css_util.parse_stylesheet_from_text('.t { box-shadow: inset 2px 4px .6px 1em rgba( 0 0 0 / 20%); }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'box-shadow': css.ShadowValue(css.Shadow{
			inset: true
			offset_x: datatypes.Length{
				amount: 2
				unit: .px
			}
			offset_y: datatypes.Length{
				amount: 4
				unit: .px
			}
			blur_radius: datatypes.Length{
				amount: 0.6
				unit: .px
			}
			spread_radius: datatypes.Length{
				amount: 1
				unit: .em
			}
			color: datatypes.Color{
				a: u8(255 * 0.2)
			}
		})
	}
}
