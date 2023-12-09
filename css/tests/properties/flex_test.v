import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = &pref.Preferences{}

fn test_flex_direction() {
	rules := css_util.parse_stylesheet_from_text('.t { flex-direction: column; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			direction: datatypes.FlexDirectionKind.column
		}
	}
}

fn test_flex_size() {
	rules := css_util.parse_stylesheet_from_text('.t { flex-grow: 2.5; flex-shrink: inherit; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			grow: 2.5
			shrink: css.Keyword('inherit')
		}
	}
}

fn test_flex_wrap() {
	rules := css_util.parse_stylesheet_from_text('.t { flex-wrap: wrap-reverse; }', preferences)!
	styles := rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			wrap: datatypes.FlexWrapKind.wrap_reverse
		}
	}
}

fn test_flex_one() {
	mut rules := css_util.parse_stylesheet_from_text('.t { flex: 2; }', preferences)!
	mut styles := rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			grow: 2.0
			basis: 0.0
		}
	}

	rules = css_util.parse_stylesheet_from_text('.t { flex: auto; }', preferences)!
	styles = rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			grow: 1.0
			shrink: 1.0
			basis: css.Keyword('auto')
		}
	}
}

fn test_flex_two() {
	mut rules := css_util.parse_stylesheet_from_text('.t { flex: 1 30px; }', preferences)!
	mut styles := rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			grow: 1.0
			shrink: 1.0
			basis: datatypes.Length{
				amount: 30
				unit: .px
			}
		}
	}

	rules = css_util.parse_stylesheet_from_text('.t { flex: 2 2; }', preferences)!
	styles = rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			grow: 2.0
			shrink: 2.0
			basis: 0.0
		}
	}
}

fn test_flex_three() {
	mut rules := css_util.parse_stylesheet_from_text('.t { flex: 2 2 10%; }', preferences)!
	mut styles := rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			grow: 2.0
			shrink: 2.0
			basis: datatypes.Percentage(0.1)
		}
	}
}

fn test_flex_flow() {
	mut rules := css_util.parse_stylesheet_from_text('.t { flex-flow: column wrap; }',
		preferences)!
	mut styles := rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			direction: datatypes.FlexDirectionKind.column
			wrap: datatypes.FlexWrapKind.wrap
		}
	}
}

fn test_flex_flow_keyword() {
	mut rules := css_util.parse_stylesheet_from_text('.t { flex-flow: inherit; }', preferences)!
	mut styles := rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			direction: css.Keyword('inherit')
			wrap: css.Keyword('inherit')
		}
	}
}

fn test_flex_merged() {
	mut rules := css_util.parse_stylesheet_from_text('.t { 
		flex: 2 2 10%;
		flex-flow: column wrap;
		flex-wrap: nowrap;
		flex-shrink: 1;
	}',
		preferences)!
	mut styles := rules.get_styles()

	assert styles == {
		'flex': css.FlexBox{
			grow: 2.0
			shrink: 1.0
			basis: datatypes.Percentage(0.1)
			wrap: datatypes.FlexWrapKind.nowrap
			direction: datatypes.FlexDirectionKind.column
		}
	}
}
