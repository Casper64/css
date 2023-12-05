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
