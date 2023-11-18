module css

import css.datatypes

const (
	zero_px = datatypes.Length{
		amount: 0
		unit: .px
	}
)

// collection of properties listed here:
// https://developer.mozilla.org/en-US/docs/Web/CSS/background
pub struct Background {
pub mut:
	color ?ColorValue
	image ?Image
}

// collection of properties listed here:
// https://developer.mozilla.org/en-US/docs/Web/CSS/border
pub struct Border {
pub mut:
	color ColorValue
	style datatypes.LineStyle
	width DimensionValue
}

// collection of properties for `margin` and `padding`:
// https://developer.mozilla.org/en-US/docs/Web/CSS/margin
pub struct MarginPadding {
pub mut:
	top    DimensionValue = css.zero_px
	right  DimensionValue = css.zero_px
	bottom DimensionValue = css.zero_px
	left   DimensionValue = css.zero_px
}

pub struct Gradient {
pub mut:
	kind            datatypes.GradientKind
	directions      datatypes.GradientDirection
	gradient_values []GradientValue
}

pub struct GradientValue {
	color ColorValue
	size  ?DimensionValue
}
