import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = &pref.Preferences{}

fn test_font_family() {
	rules := css_util.parse_stylesheet_from_text('.t { font-family: "Courier New", Courier, monospace; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'font': css.Font{
			family: ['Courier New', 'Courier', 'monospace']
		}
	}
}

fn test_font_stretch() {
	mut rules := css_util.parse_stylesheet_from_text('.t { font-stretch: semi-condensed; }',
		preferences)!
	mut styles := rules.get_styles()

	assert styles == {
		'font': css.Font{
			stretch: datatypes.FontStretchKind.semi_condensed
		}
	}

	rules = css_util.parse_stylesheet_from_text('.t { font-stretch: 25%; }', preferences)!
	styles = rules.get_styles()

	assert styles == {
		'font': css.Font{
			stretch: datatypes.Percentage(0.25)
		}
	}

	rules = css_util.parse_stylesheet_from_text('.t { font-stretch: inherit; }', preferences)!
	styles = rules.get_styles()

	assert styles == {
		'font': css.Font{
			stretch: css.Keyword('inherit')
		}
	}
}

fn test_font_weight() {
	mut rules := css_util.parse_stylesheet_from_text('.t { font-weight: 392; }', preferences)!
	mut styles := rules.get_styles()

	assert styles == {
		'font': css.Font{
			weight: 392
		}
	}

	rules = css_util.parse_stylesheet_from_text('.t { font-weight: 100.9; }', preferences)!
	styles = rules.get_styles()

	assert styles == {
		'font': css.Font{
			weight: 100
		}
	}

	rules = css_util.parse_stylesheet_from_text('.t { font-weight: normal; }', preferences)!
	styles = rules.get_styles()

	assert styles == {
		'font': css.Font{
			weight: css.Keyword('normal')
		}
	}
}
