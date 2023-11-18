module datatypes

import strconv
import strings

// See https://developer.mozilla.org/en-US/docs/Web/CSS/length#absolute_length_units
pub enum Unit {
	em
	rem
	vh
	vw
	px
}

pub struct Length {
pub mut:
	amount f64
	unit   Unit
}

// Percentage indicates a value between 0 and 100%, so 0.0 - 1.0
pub type Percentage = f64

// compatible with gx.Color
pub struct Color {
pub mut:
	r u8
	g u8
	b u8
	a u8 = 255
}

pub fn Color.from_hex(_hex string) Color {
	hex := _hex.to_lower()
	if hex.len == 3 {
		return Color{
			r: u8(strconv.parse_int(strings.repeat(hex[0], 2), 16, 0) or { 0 })
			g: u8(strconv.parse_int(strings.repeat(hex[1], 2), 16, 0) or { 0 })
			b: u8(strconv.parse_int(strings.repeat(hex[2], 2), 16, 0) or { 0 })
			a: 255
		}
	} else if hex.len == 4 {
		return Color{
			r: u8(strconv.parse_int(strings.repeat(hex[0], 2), 16, 0) or { 0 })
			g: u8(strconv.parse_int(strings.repeat(hex[1], 2), 16, 0) or { 0 })
			b: u8(strconv.parse_int(strings.repeat(hex[2], 2), 16, 0) or { 0 })
			a: u8(strconv.parse_int(strings.repeat(hex[3], 2), 16, 0) or { 0 })
		}
	} else if hex.len == 6 {
		return Color{
			r: u8(strconv.parse_int(hex[0..2], 16, 0) or { 0 })
			g: u8(strconv.parse_int(hex[2..4], 16, 0) or { 0 })
			b: u8(strconv.parse_int(hex[4..6], 16, 0) or { 0 })
			a: 255
		}
	} else if hex.len == 8 {
		return Color{
			r: u8(strconv.parse_int(hex[0..2], 16, 0) or { 0 })
			g: u8(strconv.parse_int(hex[2..4], 16, 0) or { 0 })
			b: u8(strconv.parse_int(hex[4..6], 16, 0) or { 0 })
			a: u8(strconv.parse_int(hex[6..8], 16, 0) or { 0 })
		}
	} else {
		// invalid hex color length is handled in the parser/checker
		// so no need to do that here
		return Color{}
	}
}

pub fn (c Color) int() int {
	mut v := int(c.r)
	v <<= 8
	v += c.g
	v <<= 8
	v += c.b
	v <<= 8
	v += c.a
	return v
}

pub enum LineStyle {
	@none
	hidden
	dotted
	dashed
	solid
	double
	groove
	ridge
	inset
	outset
}

pub enum GradientKind {
	linear
	radial
	repeating_linear
	repeating_radial
}

@[flag]
pub enum GradientDirection {
	top
	right
	left
	bottom
}
