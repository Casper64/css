import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = &pref.Preferences{}

fn test_single_dimensions() {
	rules := css_util.parse_stylesheet_from_text('.t { padding-left: 100vw; margin-right: 20% }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'padding': css.MarginPadding{
			left: datatypes.Length{
				amount: 100
				unit: .vw
			}
		}
		'margin':  css.MarginPadding{
			right: datatypes.Percentage(0.2)
		}
	}
}

fn test_grouped_4() {
	rules := css_util.parse_stylesheet_from_text('.t { padding: 10px 20px 30px 40px; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'padding': css.Value(css.MarginPadding{
			top: css.DimensionValue(datatypes.Length{
				amount: 10
				unit: .px
			})
			right: css.DimensionValue(datatypes.Length{
				amount: 20
				unit: .px
			})
			bottom: css.DimensionValue(datatypes.Length{
				amount: 30
				unit: .px
			})
			left: css.DimensionValue(datatypes.Length{
				amount: 40
				unit: .px
			})
		})
	}
}

fn test_grouped_3() {
	rules := css_util.parse_stylesheet_from_text('.t { padding: 10px 20px 30px; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'padding': css.Value(css.MarginPadding{
			top: css.DimensionValue(datatypes.Length{
				amount: 10
				unit: .px
			})
			right: css.DimensionValue(datatypes.Length{
				amount: 20
				unit: .px
			})
			bottom: css.DimensionValue(datatypes.Length{
				amount: 30
				unit: .px
			})
			left: css.DimensionValue(datatypes.Length{
				amount: 20
				unit: .px
			})
		})
	}
}

fn test_grouped_2() {
	rules := css_util.parse_stylesheet_from_text('.t { padding: 10px 20px; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'padding': css.Value(css.MarginPadding{
			top: css.DimensionValue(datatypes.Length{
				amount: 10
				unit: .px
			})
			right: css.DimensionValue(datatypes.Length{
				amount: 20
				unit: .px
			})
			bottom: css.DimensionValue(datatypes.Length{
				amount: 10
				unit: .px
			})
			left: css.DimensionValue(datatypes.Length{
				amount: 20
				unit: .px
			})
		})
	}
}

fn test_grouped_1() {
	rules := css_util.parse_stylesheet_from_text('.t { padding: 10px; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'padding': css.Value(css.MarginPadding{
			top: css.DimensionValue(datatypes.Length{
				amount: 10
				unit: .px
			})
			right: css.DimensionValue(datatypes.Length{
				amount: 10
				unit: .px
			})
			bottom: css.DimensionValue(datatypes.Length{
				amount: 10
				unit: .px
			})
			left: css.DimensionValue(datatypes.Length{
				amount: 10
				unit: .px
			})
		})
	}
}
