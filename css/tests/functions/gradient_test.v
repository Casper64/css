import css
import css.datatypes
import css.pref
import css.util as css_util

const (
	preferences = &pref.Preferences{}
)

fn test_gradient_simple() {
	rules := css_util.parse_stylesheet_from_text('.t { background-image: linear-gradient(red, green); }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'background-image': css.Image(css.Gradient{
			kind: .linear
			gradient_values: [css.GradientValue{
				color: 'red'
			}, css.GradientValue{
				color: 'green'
			}]
		})
	}
}

fn test_gradient_directions() {
	rules := css_util.parse_stylesheet_from_text('.t { background-image: linear-gradient(to right bottom, red, green); }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'background-image': css.Image(css.Gradient{
			kind: .linear
			directions: .right | .bottom
			gradient_values: [css.GradientValue{
				color: 'red'
			}, css.GradientValue{
				color: 'green'
			}]
		})
	}
}

fn test_gradient_dimensions() {
	rules := css_util.parse_stylesheet_from_text('.t { background-image: radial-gradient(red 10px, green 60%); }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'background-image': css.Image(css.Gradient{
			kind: .radial
			gradient_values: [
				css.GradientValue{
					color: 'red'
					size: datatypes.Length{
						amount: 10
						unit: .px
					}
				},
				css.GradientValue{
					color: 'green'
					size: datatypes.Percentage(0.6)
				},
			]
		})
	}
}
