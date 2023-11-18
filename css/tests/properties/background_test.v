import css
import css.pref
import css.util as css_util

const (
	preferences = &pref.Preferences{}
)

fn test_background_can_group() {
	rules := css_util.parse_stylesheet_from_text('.t {
		background-color: red;
		background-image: linear-gradient(red, green);
	}')!
	styles := rules.get_styles()

	assert styles == {
		'background': css.Background{
			color: 'red'
			image: css.Gradient{
				kind: .linear
				gradient_values: [css.GradientValue{
					color: 'red'
				}, css.GradientValue{
					color: 'green'
				}]
			}
		}
	}
}

fn test_background_can_merge() {
	rules := css_util.parse_stylesheet_from_text('.t {
		background-color: red;
	}
	.u {
		background-image: linear-gradient(red, green);
	}')!
	styles := rules.get_styles()

	assert styles == {
		'background': css.Background{
			color: 'red'
			image: css.Gradient{
				kind: .linear
				gradient_values: [css.GradientValue{
					color: 'red'
				}, css.GradientValue{
					color: 'green'
				}]
			}
		}
	}
}