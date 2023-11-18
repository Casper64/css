module css

import css.datatypes

// collection of properties listed here:
// https://developer.mozilla.org/en-US/docs/Web/CSS/background
pub struct Background {
pub mut:
	color ColorValue
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
	top    DimensionValue
	right  DimensionValue
	bottom DimensionValue
	left   DimensionValue
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
