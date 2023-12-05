module css

import css.datatypes

const zero_px = datatypes.Length{
	amount: 0
	unit: .px
}

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
	colors   BorderColors
	styles   BorderStyles
	widths   FourDimensions
	collapse Keyword = 'separate'
}

pub struct BorderColors {
pub mut:
	top    ?ColorValue
	right  ?ColorValue
	bottom ?ColorValue
	left   ?ColorValue
}

pub struct BorderStyles {
pub mut:
	top    BorderLineStyle = datatypes.LineStyle.@none
	right  BorderLineStyle = datatypes.LineStyle.@none
	bottom BorderLineStyle = datatypes.LineStyle.@none
	left   BorderLineStyle = datatypes.LineStyle.@none
}

// For properties like `margin` and `padding` that can have 4 dimensions values
// https://developer.mozilla.org/en-US/docs/Web/CSS/margin
pub struct FourDimensions {
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

pub struct Text {
pub mut:
	align           ?string
	align_last      ?string
	combine_upright ?TextCombineUpright
	// decoration
	// emphasis
	indent      ?DimensionValue
	justify     ?string
	orientation ?string
	overflow    ?TextOverflow
	rendering   ?string
	shadow      []Shadow
	transform   ?string
	wrap        ?string
}

pub struct Shadow {
pub mut:
	offset_x      DimensionValue
	offset_y      DimensionValue
	blur_radius   DimensionValue = css.zero_px
	spread_radius DimensionValue = css.zero_px
	inset         bool
	color         ColorValue
}

pub struct Overflow {
pub mut:
	overflow_x Keyword = 'visible'
	overflow_y Keyword = 'visible'
}
