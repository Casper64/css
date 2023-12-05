import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = &pref.Preferences{}

fn test_border_color_keyword() {
	rules := css_util.parse_stylesheet_from_text('.t { border-color: unset; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			colors: css.BorderColors{'unset', 'unset', 'unset', 'unset'}
		}
	}
}

fn test_border_color_one() {
	rules := css_util.parse_stylesheet_from_text('.t { border-color: red; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			colors: css.BorderColors{'red', 'red', 'red', 'red'}
		}
	}
}

fn test_border_color_two() {
	rules := css_util.parse_stylesheet_from_text('.t { border-color: red green; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			colors: css.BorderColors{'red', 'green', 'red', 'green'}
		}
	}
}

fn test_border_color_three() {
	rules := css_util.parse_stylesheet_from_text('.t { border-color: red green yellow; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			colors: css.BorderColors{'red', 'green', 'yellow', 'green'}
		}
	}
}

fn test_border_color_four() {
	rules := css_util.parse_stylesheet_from_text('.t { border-color: red green yellow orange; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			colors: css.BorderColors{'red', 'green', 'yellow', 'orange'}
		}
	}
}

fn test_merge_colors() {
	rules := css_util.parse_stylesheet_from_text('.t { border-color: yellow; border-top-color: red; border-right-color: green; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			colors: css.BorderColors{
				top: 'red'
				right: 'green'
				left: 'yellow'
				bottom: 'yellow'
			}
		}
	}
}

fn test_border_style_keyword() {
	rules := css_util.parse_stylesheet_from_text('.t { border-style: unset; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{css.Keyword('unset'), css.Keyword('unset'), css.Keyword('unset'), css.Keyword('unset')}
		}
	}
}

fn test_border_style_one() {
	rules := css_util.parse_stylesheet_from_text('.t { border-style: dotted; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{datatypes.LineStyle.dotted, datatypes.LineStyle.dotted, datatypes.LineStyle.dotted, datatypes.LineStyle.dotted}
		}
	}
}

fn test_border_style_two() {
	rules := css_util.parse_stylesheet_from_text('.t { border-style: dotted none; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{datatypes.LineStyle.dotted, datatypes.LineStyle.@none, datatypes.LineStyle.dotted, datatypes.LineStyle.@none}
		}
	}
}

fn test_border_style_three() {
	rules := css_util.parse_stylesheet_from_text('.t { border-style: dotted none hidden; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{datatypes.LineStyle.dotted, datatypes.LineStyle.@none, datatypes.LineStyle.hidden, datatypes.LineStyle.@none}
		}
	}
}

fn test_border_style_four() {
	rules := css_util.parse_stylesheet_from_text('.t { border-style: dotted none hidden ridge; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{datatypes.LineStyle.dotted, datatypes.LineStyle.@none, datatypes.LineStyle.hidden, datatypes.LineStyle.ridge}
		}
	}
}

fn test_border_style_merged() {
	rules := css_util.parse_stylesheet_from_text('.t { border-style: dotted; border-top-style: ridge; border-right-style: unset; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{datatypes.LineStyle.ridge, css.Keyword('unset'), datatypes.LineStyle.dotted, datatypes.LineStyle.dotted}
		}
	}
}

fn test_border_width_merged() {
	rules := css_util.parse_stylesheet_from_text('.t { border-width: 10px; border-top-width: 20px; border-right-width: 30px; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			widths: css.FourDimensions{datatypes.Length{
				amount: 20
				unit: .px
			}, datatypes.Length{
				amount: 30
				unit: .px
			}, datatypes.Length{
				amount: 10
				unit: .px
			}, datatypes.Length{
				amount: 10
				unit: .px
			}}
		}
	}
}
