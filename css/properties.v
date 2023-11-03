module css

import css.datatypes

// pub type Width = DimensionValue
// pub type Height = DimensionValue
// pub type Top = DimensionValue
// pub type Right = DimensionValue
// pub type Bottom = DimensionValue
// pub type Left = DimensionValue

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

// collection of properties listed here:
// https://developer.mozilla.org/en-US/docs/Web/CSS/margin
pub struct Margin {
pub mut:
	top    DimensionValue
	right  DimensionValue
	bottom DimensionValue
	left   DimensionValue
}

// collection of properties listed here:
// https://developer.mozilla.org/en-US/docs/Web/CSS/padding
pub struct Padding {
pub mut:
	top    DimensionValue
	right  DimensionValue
	bottom DimensionValue
	left   DimensionValue
}
