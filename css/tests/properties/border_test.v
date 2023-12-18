import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = pref.Preferences{}

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

fn test_border_keyword() {
	rules := css_util.parse_stylesheet_from_text('.t { border: inherit; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			colors: css.BorderColors{css.Keyword('inherit'), css.Keyword('inherit'), css.Keyword('inherit'), css.Keyword('inherit')}
			styles: css.BorderStyles{css.Keyword('inherit'), css.Keyword('inherit'), css.Keyword('inherit'), css.Keyword('inherit')}
			widths: css.FourDimensions{css.Keyword('inherit'), css.Keyword('inherit'), css.Keyword('inherit'), css.Keyword('inherit')}
		}
	}
}

fn test_border_single_style() {
	rules := css_util.parse_stylesheet_from_text('.t { border: dotted; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{datatypes.LineStyle.dotted, datatypes.LineStyle.dotted, datatypes.LineStyle.dotted, datatypes.LineStyle.dotted}
		}
	}
}

fn test_border_width_style() {
	rules := css_util.parse_stylesheet_from_text('.t { border: 2px dotted; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{datatypes.LineStyle.dotted, datatypes.LineStyle.dotted, datatypes.LineStyle.dotted, datatypes.LineStyle.dotted}
			widths: css.FourDimensions{datatypes.Length{
				amount: 2
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}}
		}
	}
}

fn test_border_style_color() {
	rules := css_util.parse_stylesheet_from_text('.t { border: outset #f33; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{datatypes.LineStyle.outset, datatypes.LineStyle.outset, datatypes.LineStyle.outset, datatypes.LineStyle.outset}
			colors: css.BorderColors{datatypes.Color{
				r: 255
				g: 51
				b: 51
			}, datatypes.Color{
				r: 255
				g: 51
				b: 51
			}, datatypes.Color{
				r: 255
				g: 51
				b: 51
			}, datatypes.Color{
				r: 255
				g: 51
				b: 51
			}}
		}
	}
}

fn test_border_all() {
	rules := css_util.parse_stylesheet_from_text('.t { border: green dashed 2px; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{datatypes.LineStyle.dashed, datatypes.LineStyle.dashed, datatypes.LineStyle.dashed, datatypes.LineStyle.dashed}
			colors: css.BorderColors{'green', 'green', 'green', 'green'}
			widths: css.FourDimensions{datatypes.Length{
				amount: 2
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}}
		}
	}
}

fn test_border_merged() {
	rules := css_util.parse_stylesheet_from_text('.t { 
		border-collapse: collapse; 
		border: green dashed 2px; 
		border-top-width: 4px; 
		border-right-color: red; 
		border-bottom-style: dotted; 
	}',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			collapse: 'collapse'
			styles: css.BorderStyles{datatypes.LineStyle.dashed, datatypes.LineStyle.dashed, datatypes.LineStyle.dotted, datatypes.LineStyle.dashed}
			colors: css.BorderColors{'green', 'red', 'green', 'green'}
			widths: css.FourDimensions{datatypes.Length{
				amount: 4
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}}
		}
	}
}

fn test_single_border() {
	rules := css_util.parse_stylesheet_from_text('.t {
		border: red dashed 2px;
		border-bottom: green dotted 4px;
		border-bottom-color: yellow;
	}',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			styles: css.BorderStyles{datatypes.LineStyle.dashed, datatypes.LineStyle.dashed, datatypes.LineStyle.dotted, datatypes.LineStyle.dashed}
			colors: css.BorderColors{'red', 'red', 'yellow', 'red'}
			widths: css.FourDimensions{datatypes.Length{
				amount: 2
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}, datatypes.Length{
				amount: 4
				unit: .px
			}, datatypes.Length{
				amount: 2
				unit: .px
			}}
		}
	}
}

fn test_border_radius() {
	rules := css_util.parse_stylesheet_from_text('.t {
		border-radius: 10% / 50% 25%;
	}',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			radius: css.BorderRadius{
				top_left: [datatypes.Percentage(0.1), datatypes.Percentage(0.5)]
				top_right: [datatypes.Percentage(0.1), datatypes.Percentage(0.25)]
				bottom_right: [datatypes.Percentage(0.1), datatypes.Percentage(0.5)]
				bottom_left: [datatypes.Percentage(0.1), datatypes.Percentage(0.25)]
			}
		}
	}
}

fn test_border_radius_merged() {
	rules := css_util.parse_stylesheet_from_text('.t {
		border-radius: 10% / 50% 25%;
		border-top-left-radius: 30%;
	}',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'border': css.Border{
			radius: css.BorderRadius{
				top_left: [datatypes.Percentage(0.3), datatypes.Percentage(0.3)]
				top_right: [datatypes.Percentage(0.1), datatypes.Percentage(0.25)]
				bottom_right: [datatypes.Percentage(0.1), datatypes.Percentage(0.5)]
				bottom_left: [datatypes.Percentage(0.1), datatypes.Percentage(0.25)]
			}
		}
	}
}
