module css

import css.datatypes

pub enum UrlKind {
	link // http://
	data // data:image/png;base64,
	file // myFont.woff
	element // #IDofSVGpath
}

pub struct Url {
pub mut:
	kind  UrlKind
	value string
}

pub fn (u1 Url) == (u2 Url) bool {
	if u1.kind != u2.kind {
		return false
	}

	return u1.value == u2.value
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
