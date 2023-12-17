module checker

import css
import css.ast
import css.datatypes
import css.errors

pub fn replace_vendor_prefix(property string) string {
	mut res := property
	for prefix in vendor_prefixes {
		res = res.replace(prefix, '')
	}
	return res
}

pub fn (mut c Checker) validate_declarations(declarations []ast.Node) map[string]css.RawValue {
	mut style_map := map[string]css.RawValue{}

	for decl in declarations {
		match decl {
			ast.Declaration {
				// remove browser prefix
				prop_name := replace_vendor_prefix(decl.property)

				if value := c.validator.validate_property(prop_name, decl.value) {
					// use normal property name to include browser prefix
					style_map[decl.property] = css.RawValue{
						important: decl.important
						value: value
					}
				} else {
					if err is ast.NodeError {
						c.error_with_pos(err.msg(), err.pos)
					} else {
						if err.msg() != 'variable' {
							c.error_with_pos(err.msg(), decl.pos)
						}
					}
				}
			}
			ast.Raw {
				c.error_with_pos('invalid or unsupported declaration', decl.pos)
			}
			else {
				c.error_with_pos('expecting a CSS declaration', decl.pos())
			}
		}
	}

	return style_map
}

pub fn (mut pv PropertyValidator) validate_property(property string, raw_value ast.Value) !css.Value {
	// CSS variable
	if property.starts_with('--') {
		// return css.Variable{
		// 	name: property
		// 	value: raw_value
		// }
		pv.variables[property] = raw_value
		return error('variable')
	}
	match property {
		'color' {
			return pv.validate_single_color_prop(property, raw_value)!
		}
		'block-size', 'bottom', 'column-gap', 'flex-basis', 'font-size', 'height', 'inline-size',
		'left', 'letter-spacing', 'line-height', 'max-height', 'max-width', 'min-height',
		'min-width', 'order', 'orphans', 'perspective', 'right', 'row-gap', 'tab-size',
		'text-indent', 'top', 'vertical-align', 'widows', 'width', 'word-spacing', 'z-index' {
			return pv.validate_single_dimension_prop(property, raw_value)!
		}
		'opacity' {
			return pv.validate_alpha_value_prop(property, raw_value)!
		}
		'padding', 'margin', 'border-width' {
			return pv.validate_4_dim_value_prop(property, raw_value)!
		}
		'content' {
			return pv.validate_single_string(property, raw_value)!
		}
		// TODO: these values aren't used that often, check if it's faster to match them at the end of the `else` clause
		'align-content', 'align-items', 'align-self', 'all', 'appearance', 'backface-visibility',
		'border-collapse', 'box-sizing', 'caption-side', 'clear', 'cursor', 'direction', 'display',
		'empty-cells', 'float', 'font-style', 'forced-color-adjust', 'isolation',
		'justify-content', 'justify-items', 'justify-self', 'mix-blend-mode', 'object-fit',
		'overflow-x', 'overflow-y', 'pointer-events', 'position', 'print-color-adjust', 'resize',
		'scroll-behavior', 'table-layout', 'text-align', 'text-align-last', 'text-justify',
		'text-rendering', 'text-transform', 'text-wrap', 'touch-action', 'unicode-bidi',
		'user-select', 'visibility', 'white-space', 'word-break', 'word-wrap', 'writing-mode' {
			return pv.validate_single_keyword_prop(property, raw_value)!
		}
		'flex-grow', 'flex-shrink' {
			return pv.valdiate_flex_size(property, raw_value)!
		}
		'flex-direction' {
			return pv.validate_flex_direction(property, raw_value)!
		}
		'flex-wrap' {
			return pv.validate_flex_wrap(property, raw_value)!
		}
		'flex-flow' {
			return pv.validate_flex_flow(raw_value)!
		}
		'flex' {
			return pv.validate_flex(raw_value)!
		}
		'border' {
			return pv.validate_border(raw_value)!
		}
		'border-top', 'border-right', 'border-bottom', 'border-left' {
			return pv.validate_single_border(property, raw_value)!
		}
		'border-color' {
			return pv.validate_border_color(raw_value)!
		}
		'border-style' {
			return pv.validate_border_style(raw_value)!
		}
		'border-radius' {
			return pv.validate_border_radius(raw_value)!
		}
		'text-overflow' {
			return pv.validate_text_overflow(raw_value)!
		}
		'text-combine-upright' {
			return pv.validate_text_combine_upright(raw_value)!
		}
		'overflow' {
			return pv.validate_overflow(raw_value)!
		}
		'font-family' {
			return pv.validate_font_family(raw_value)!
		}
		'font-stretch' {
			return pv.validate_font_stretch(raw_value)!
		}
		'font-weight' {
			return pv.validate_font_weight(raw_value)!
		}
		else {
			// handle properties with similair endings / starts
			if property.starts_with('background') {
				return pv.validate_background(property, raw_value)
			} else if property.ends_with('-color') {
				// for properties like `background-color`, or `border-left-color`
				return pv.validate_single_color_prop(property, raw_value)!
			} else if property.starts_with('margin-') || property.starts_with('padding-') {
				// for properties like `margin-left`, or `padding-top`
				return pv.validate_4dim_prop(property, raw_value)!
			} else if property.ends_with('-shadow') {
				return pv.validate_shadow(property, raw_value)!
			} else if property.starts_with('border-') {
				if property.ends_with('-style') {
					return pv.validate_single_border_style(property, raw_value)!
				} else if property.ends_with('-width') {
					return pv.validate_single_dimension_prop(property, raw_value)!
				} else if property.ends_with('-radius') {
					return pv.validate_single_border_radius(property, raw_value)!
				}
			}
		}
	}

	return error(pv.unsupported_property(property))
}

pub fn (pv &PropertyValidator) validate_single_keyword_prop(property_name string, raw_value ast.Value) !css.Keyword {
	if raw_value.children.len != 1 {
		return ast.NodeError{
			msg: 'property "${property_name}" only expects 1 value!'
			pos: raw_value.pos
		}
	}

	keyword_value := raw_value.children[0]
	if keyword_value is ast.Ident {
		return css.Keyword(keyword_value.name)
	} else {
		return ast.NodeError{
			msg: 'expecting a CSS keyword'
			pos: keyword_value.pos()
		}
	}
}

// any property that has only 1 color value like `color: `, or `background-color: `
pub fn (pv &PropertyValidator) validate_single_color_prop(property_name string, raw_value ast.Value) !css.ColorValue {
	if raw_value.children.len != 1 {
		return ast.NodeError{
			msg: 'property "${property_name}" only expects 1 value!'
			pos: raw_value.pos
		}
	}

	color_value := raw_value.children[0]
	return pv.validate_single_color(property_name, color_value)
}

pub fn (pv &PropertyValidator) validate_single_color(property_name string, color_value ast.Node) !css.ColorValue {
	match color_value {
		ast.Ident {
			// named color or keyword
			return color_value.name
		}
		ast.Hash {
			return datatypes.Color.from_hex(color_value.value)
		}
		ast.Function {
			return match color_value.name {
				// apparently rgba is legacy syntax...
				'rgb', 'rgba' {
					pv.validate_fn_rgb(color_value)!
				}
				// TODO: var()
				else {
					ast.NodeError{
						msg: 'unsupported function "${color_value.name}" for property "${property_name}".\n${errors.did_you_mean(valid_color_functions)}'
						pos: color_value.pos
					}
				}
			}
		}
		else {
			return ast.NodeError{
				msg: 'invalid value for property "${property_name}"!'
				pos: color_value.pos()
			}
		}
	}
}

pub fn (pv &PropertyValidator) validate_single_string(property_name string, raw_value ast.Value) !string {
	if raw_value.children.len != 1 {
		return ast.NodeError{
			msg: 'property "${property_name}" only expects 1 value!'
			pos: raw_value.pos
		}
	}

	string_value := raw_value.children[0]
	if string_value is ast.String {
		return string_value.value
	} else {
		return ast.NodeError{
			msg: 'expecting a string'
			pos: string_value.pos()
		}
	}
}

// any property that has only 1 dimension value, such as width and height
pub fn (pv &PropertyValidator) validate_single_dimension_prop(prop_name string, raw_value ast.Value) !css.DimensionValue {
	if raw_value.children.len != 1 {
		return ast.NodeError{
			msg: 'property "${prop_name}" only expects 1 value!'
			pos: raw_value.pos
		}
	}

	dimension_value := raw_value.children[0]
	return pv.validate_dimension(prop_name, dimension_value)
}

pub fn (pv &PropertyValidator) validate_dimension(prop_name string, dimension_value ast.Node) !css.DimensionValue {
	match dimension_value {
		ast.Dimension {
			unit := match dimension_value.unit {
				'px' {
					datatypes.Unit.px
				}
				'vw' {
					datatypes.Unit.vw
				}
				'vh' {
					datatypes.Unit.vh
				}
				'em' {
					datatypes.Unit.em
				}
				'rem' {
					datatypes.Unit.rem
				}
				'%' {
					return datatypes.Percentage(dimension_value.value.f64() / 100)
				}
				else {
					return ast.NodeError{
						msg: 'unsupported unit "${dimension_value.unit}".\n${errors.did_you_mean(valid_units)}'
						pos: dimension_value.pos
					}
				}
			}

			return datatypes.Length{
				amount: dimension_value.value.f64()
				unit: unit
			}
		}
		ast.Number {
			return dimension_value.value.f64()
		}
		ast.Ident {
			return css.Keyword(dimension_value.name)
		}
		// TODO: calc & var
		else {
			return ast.NodeError{
				msg: 'invalid value for property "${prop_name}"!'
				pos: dimension_value.pos()
			}
		}
	}
}

pub fn (pv &PropertyValidator) validate_alpha_value_prop(prop_name string, raw_value ast.Value) !css.AlphaValue {
	if raw_value.children.len != 1 {
		return ast.NodeError{
			msg: 'property "${prop_name}" only expects 1 value!'
			pos: raw_value.pos
		}
	}

	alpha_value := raw_value.children[0]
	mut v := 0.0
	match alpha_value {
		ast.Number {
			v = alpha_value.value.f64()
		}
		ast.Dimension {
			if alpha_value.unit != '%' {
				return ast.NodeError{
					msg: 'expecting a percentage'
					pos: alpha_value.pos
				}
			}

			v = alpha_value.value.f64() / 100
		}
		ast.Ident {
			return css.Keyword(alpha_value.name)
		}
		else {
			return ast.NodeError{
				msg: 'invalid value for property "${prop_name}", expecting a number or a percentage'
				pos: raw_value.pos
			}
		}
	}

	if v < 0 || v > 1 {
		return ast.NodeError{
			msg: 'Alpha value must be a percentage between 0-100% or between 0 and 1'
			pos: raw_value.pos
		}
	}
	return v
}

pub fn (pv &PropertyValidator) validate_4dim_prop(prop_name string, raw_value ast.Value) !css.Value {
	if four_dim_endings.any(fn [prop_name] (ending string) bool {
		return prop_name.ends_with(ending)
	})
	{
		return pv.validate_single_dimension_prop(prop_name, raw_value)!
	}

	return error(pv.unsupported_property(prop_name))
}

pub fn (pv &PropertyValidator) validate_4_dim_value_prop(prop_name string, raw_value ast.Value) !css.FourDimensions {
	if raw_value.children.len > 4 {
		return ast.NodeError{
			msg: 'property "${prop_name}" can have a maximum of 4 values'
			pos: raw_value.children[4].pos()
		}
	}

	mut vals := []css.DimensionValue{}
	for value in raw_value.children {
		vals << pv.validate_single_dimension_prop(prop_name, ast.Value{
			pos: value.pos()
			children: [value]
		})!
	}

	if vals.len == 1 {
		return css.FourDimensions{vals[0], vals[0], vals[0], vals[0]}
	} else if vals.len == 2 {
		return css.FourDimensions{vals[0], vals[1], vals[0], vals[1]}
	} else if vals.len == 3 {
		return css.FourDimensions{vals[0], vals[1], vals[2], vals[1]}
	} else {
		return css.FourDimensions{vals[0], vals[1], vals[2], vals[3]}
	}
}

pub fn (pv &PropertyValidator) validate_image(prop_name string, raw_value ast.Value) !css.Image {
	for item in raw_value.children {
		match item {
			ast.Function {
				if item.name.ends_with('-gradient') {
					return pv.validate_fn_gradients(prop_name, item.name, item)!
				} else if item.name == 'url' {
					return pv.validate_fn_url(item.name, item)!
				} else {
					return ast.NodeError{
						msg: 'Invalid function for property "${prop_name}".\n${errors.did_you_mean(valid_image_fns)}'
						pos: item.pos
					}
				}
			}
			else {
				return ast.NodeError{
					msg: 'invalid or unsupported value for "${prop_name}"'
					pos: item.pos()
				}
			}
		}
	}

	return error(pv.unsupported_property(prop_name))
}

pub fn (pv &PropertyValidator) validate_background(prop_name string, raw_value ast.Value) !css.Value {
	match prop_name {
		'background-color' {
			return pv.validate_single_color_prop(prop_name, raw_value)!
		}
		'background-attachement', 'background-blend-mode', 'background-clip' {
			return pv.validate_single_keyword_prop(prop_name, raw_value)!
		}
		'background-image' {
			return pv.validate_image(prop_name, raw_value)!
		}
		// 'background-position' {
		// 	return pv.validate_background_position(raw_value)!
		// }
		else {
			return error(pv.unsupported_property(prop_name))
		}
	}
}

// pub fn (pv &PropertyValidator) validate_background_position(raw_value ast.Value)

pub fn (pv &PropertyValidator) validate_text_overflow(raw_value ast.Value) !css.TextOverflow {
	if raw_value.children.len > 2 {
		return ast.NodeError{
			msg: 'property "text-overflow" can have 1 or 2 values'
			pos: raw_value.pos
		}
	}

	mut keyword := ''
	first_val := raw_value.children[0]

	if first_val is ast.Ident {
		keyword = first_val.name
	} else {
		return ast.NodeError{
			msg: 'expecting a keyword'
			pos: first_val.pos()
		}
	}

	if raw_value.children.len == 1 {
		return css.Keyword(keyword)
	} else if keyword != 'ellipsis' {
		return ast.NodeError{
			msg: 'only the keyword "ellipsis" can have a second value for property "text-overflow"'
			pos: raw_value.pos
		}
	} else {
		ellipsis_child := raw_value.children[1]
		if ellipsis_child is ast.String {
			return css.TextEllipsis(ellipsis_child.value)
		} else {
			return ast.NodeError{
				msg: 'expecting a string'
				pos: ellipsis_child.pos()
			}
		}
	}
}

pub fn (pv &PropertyValidator) validate_text_combine_upright(raw_value ast.Value) !css.TextCombineUpright {
	if raw_value.children.len > 2 {
		return ast.NodeError{
			msg: 'property "text-combine-upright" can have 1 or 2 values'
			pos: raw_value.pos
		}
	}

	mut keyword := ''
	first_val := raw_value.children[0]

	if first_val is ast.Ident {
		keyword = first_val.name
	} else {
		return ast.NodeError{
			msg: 'expecting a keyword'
			pos: first_val.pos()
		}
	}

	if raw_value.children.len == 1 {
		return css.Keyword(keyword)
	} else if keyword != 'digits' {
		return ast.NodeError{
			msg: 'only the keyword "digits" can have a second value for property "text-combine-upright"'
			pos: raw_value.pos
		}
	} else {
		digit_child := raw_value.children[1]
		if digit_child is ast.Number {
			return css.TextCombineUprightDigits(digit_child.value.int())
		} else {
			return ast.NodeError{
				msg: 'expecting a number'
				pos: digit_child.pos()
			}
		}
	}
}

pub fn (pv &PropertyValidator) validate_shadow(prop_name string, raw_value ast.Value) !css.Value {
	if raw_value.children.len == 1 {
		keyword_child := raw_value.children[0]
		if keyword_child is ast.Ident {
			return css.Keyword(keyword_child.name)
		}
	}

	mut shadow := css.Shadow{}
	mut dimension_values := []css.DimensionValue{}
	mut color_value := ?css.ColorValue(none)

	for child in raw_value.children {
		match child {
			ast.Ident {
				if child.name == 'inset' {
					if shadow.inset {
						return ast.NodeError{
							msg: 'keyword "inset" is already used'
							pos: child.pos
						}
					} else {
						shadow.inset = true
					}
				} else {
					// the value is a color
					if color_value != none {
						return ast.NodeError{
							msg: 'only 1 color is allowed for property "${prop_name}"'
							pos: child.pos
						}
					} else {
						color_value = child.name
					}
				}
			}
			ast.Dimension, ast.Number {
				dimension_values << pv.validate_dimension(prop_name, child)!
			}
			ast.Function {
				// the value is a color
				// TODO: calc functions?
				if color_value != none {
					return ast.NodeError{
						msg: 'only 1 color is allowed for property "${prop_name}"'
						pos: child.pos
					}
				} else {
					color_value = pv.validate_single_color(prop_name, child)!
				}
			}
			ast.Hash {
				if color_value != none {
					return ast.NodeError{
						msg: 'only 1 color is allowed for property "${prop_name}"'
						pos: child.pos
					}
				} else {
					color_value = pv.validate_single_color(prop_name, child)!
				}
			}
			else {
				return ast.NodeError{
					msg: 'invalid value for property "${prop_name}"!'
					pos: child.pos()
				}
			}
		}
	}

	if color := color_value {
		shadow.color = color
	} else {
		return ast.NodeError{
			msg: 'a shadow property must specify a color!'
			pos: raw_value.pos
		}
	}

	if dimension_values.len == 1 || dimension_values.len > 4 {
		return ast.NodeError{
			msg: 'expecting 0, 2, 3 or 4 length values for property "${prop_name}" not ${dimension_values.len}'
			pos: raw_value.pos
		}
	}

	if dimension_values.len >= 2 {
		shadow.offset_x = dimension_values[0]
		shadow.offset_y = dimension_values[1]
	}
	if dimension_values.len >= 3 {
		shadow.blur_radius = dimension_values[2]
	}
	if dimension_values.len == 4 {
		shadow.spread_radius = dimension_values[3]
	}

	return shadow
}

pub fn (pv &PropertyValidator) validate_overflow(raw_value ast.Value) !css.Overflow {
	mut keywords := []string{}

	for child in raw_value.children {
		match child {
			ast.Ident {
				keywords << child.name
			}
			else {
				return ast.NodeError{
					msg: 'invalid value for property "overflow"'
					pos: child.pos()
				}
			}
		}
	}

	if keywords.len > 2 {
		return ast.NodeError{
			msg: 'expecting 1 or 2 values for property "overflow" not ${keywords.len}'
			pos: raw_value.pos
		}
	} else if keywords.len == 2 {
		return css.Overflow{keywords[0], keywords[1]}
	} else {
		return css.Overflow{keywords[0], keywords[0]}
	}
}

pub fn (pv &PropertyValidator) validate_border_color(raw_value ast.Value) !css.BorderColors {
	mut vals := []css.ColorValue{}

	for child in raw_value.children {
		vals << pv.validate_single_color('border-color', child)!
	}

	if vals.len == 1 {
		return css.BorderColors{vals[0], vals[0], vals[0], vals[0]}
	} else if vals.len == 2 {
		return css.BorderColors{vals[0], vals[1], vals[0], vals[1]}
	} else if vals.len == 3 {
		return css.BorderColors{vals[0], vals[1], vals[2], vals[1]}
	} else if vals.len == 4 {
		return css.BorderColors{vals[0], vals[1], vals[2], vals[3]}
	} else {
		return ast.NodeError{
			msg: 'property "border-color" can have a maximum of 4 values!'
			pos: raw_value.pos
		}
	}
}

pub fn (pv &PropertyValidator) validate_single_border_style(prop_name string, raw_value ast.Value) !css.BorderLineStyle {
	if raw_value.children.len > 1 {
		return ast.NodeError{
			msg: 'property "${prop_name}" only expects 1 value!'
			pos: raw_value.pos
		}
	}

	return pv.validate_border_style_value(prop_name, raw_value.children[0])
}

pub fn (pv &PropertyValidator) validate_border_style_value(prop_name string, node ast.Node) !css.BorderLineStyle {
	match node {
		ast.Ident {
			match node.name {
				'none' {
					return datatypes.LineStyle.@none
				}
				'hidden' {
					return datatypes.LineStyle.hidden
				}
				'dotted' {
					return datatypes.LineStyle.dotted
				}
				'dashed' {
					return datatypes.LineStyle.dashed
				}
				'solid' {
					return datatypes.LineStyle.solid
				}
				'double' {
					return datatypes.LineStyle.double
				}
				'groove' {
					return datatypes.LineStyle.groove
				}
				'ridge' {
					return datatypes.LineStyle.ridge
				}
				'inset' {
					return datatypes.LineStyle.inset
				}
				'outset' {
					return datatypes.LineStyle.outset
				}
				else {
					return css.Keyword(node.name)
				}
			}
		}
		else {}
	}
	return ast.NodeError{
		msg: 'invalid value for property "${prop_name}"!'
		pos: node.pos()
	}
}

pub fn (pv &PropertyValidator) validate_border_style(raw_value ast.Value) !css.BorderStyles {
	mut vals := []css.BorderLineStyle{}

	for child in raw_value.children {
		vals << pv.validate_border_style_value('border-style', child)!
	}

	if vals.len == 1 {
		return css.BorderStyles{vals[0], vals[0], vals[0], vals[0]}
	} else if vals.len == 2 {
		return css.BorderStyles{vals[0], vals[1], vals[0], vals[1]}
	} else if vals.len == 3 {
		return css.BorderStyles{vals[0], vals[1], vals[2], vals[1]}
	} else if vals.len == 4 {
		return css.BorderStyles{vals[0], vals[1], vals[2], vals[3]}
	} else {
		return ast.NodeError{
			msg: 'property "border-style" can have a maximum of 4 values!'
			pos: raw_value.pos
		}
	}
}

pub fn (pv &PropertyValidator) validate_border(raw_value ast.Value) !css.Border {
	single_border := pv.validate_single_border('border', raw_value)!

	return css.Border{
		colors: css.BorderColors{single_border.color, single_border.color, single_border.color, single_border.color}
		styles: css.BorderStyles{single_border.style, single_border.style, single_border.style, single_border.style}
		widths: css.FourDimensions{single_border.width, single_border.width, single_border.width, single_border.width}
	}
}

pub fn (pv &PropertyValidator) validate_single_border(prop_name string, raw_value ast.Value) !css.SingleBorder {
	mut border := css.SingleBorder{}

	if raw_value.children.len == 1 {
		child := raw_value.children[0]
		if child is ast.Number && child.value == '0' {
			border.width = 0.0
			return border
		}

		style := pv.validate_border_style_value(prop_name, child)!
		border.style = style

		if style is css.Keyword {
			// all should be this keyword
			border.color = style
			border.width = style
		}
		// else it's only a style value
		return border
	} else if raw_value.children.len > 3 {
		return ast.NodeError{
			msg: 'property "border" can have a maximum of 3 values!'
			pos: raw_value.pos
		}
	}

	mut color := ?css.ColorValue(none)
	mut style := ?css.BorderLineStyle(none)
	mut width := ?css.DimensionValue(none)

	for child in raw_value.children {
		match child {
			ast.Dimension {
				if width != none {
					return ast.NodeError{
						msg: 'only 1 dimension value is allowed for property "${prop_name}"'
						pos: child.pos
					}
				}
				width = pv.validate_dimension(prop_name, child)!
			}
			ast.Ident {
				style_val := pv.validate_border_style_value(prop_name, child)!
				if style_val is css.Keyword {
					// it's a color
					if color != none {
						return ast.NodeError{
							msg: 'only 1 color value is allowed for property "${prop_name}"'
							pos: child.pos
						}
					}
					color = style_val
				} else {
					// it's a style
					if style != none {
						return ast.NodeError{
							msg: 'only 1 border-style value is allowed for property "${prop_name}"'
							pos: child.pos
						}
					}
					style = style_val
				}
			}
			ast.Hash, ast.Function {
				if color != none {
					return ast.NodeError{
						msg: 'only 1 color value is allowed for property "${prop_name}"'
						pos: child.pos
					}
				}
				color = pv.validate_single_color(prop_name, child)!
			}
			else {}
		}
	}

	if c := color {
		border.color = c
	}
	if s := style {
		border.style = s
	}
	if w := width {
		border.width = w
	}
	return border
}

pub fn (pv &PropertyValidator) validate_border_radius(raw_value ast.Value) !css.BorderRadius {
	mut slash_idx := ?int(none)

	for i, child in raw_value.children {
		match child {
			ast.Operator {
				if child.kind == .div {
					if slash_idx != none {
						return ast.NodeError{
							msg: 'only one "/" is allowed for property "border-radius"'
							pos: child.pos
						}
					} else {
						slash_idx = i
					}
				} else {
					return ast.NodeError{
						msg: 'invalid value for property "border-radius"'
						pos: child.pos
					}
				}
			}
			else {}
		}
	}

	mut normal_radiae := css.FourDimensions{}
	mut extra_radiae := css.FourDimensions{}

	if si := slash_idx {
		if si == raw_value.children.len - 1 {
			return ast.NodeError{
				msg: 'expecting a length or percentage after "/"'
				pos: raw_value.children.last().pos()
			}
		}

		normal_radiae = pv.validate_4_dim_value_prop('border-radius', ast.Value{
			children: raw_value.children[..si]
			pos: raw_value.pos
		})!
		extra_radiae = pv.validate_4_dim_value_prop('border-radius', ast.Value{
			children: raw_value.children[si + 1..]
			pos: raw_value.pos
		})!
	} else {
		normal_radiae = pv.validate_4_dim_value_prop('border-radius', raw_value)!
		extra_radiae = normal_radiae
	}

	return css.BorderRadius{[normal_radiae.top, extra_radiae.top], [normal_radiae.right, extra_radiae.right], [
		normal_radiae.bottom,
		extra_radiae.bottom,
	], [normal_radiae.left, extra_radiae.left]}
}

pub fn (pv &PropertyValidator) validate_single_border_radius(prop_name string, raw_value ast.Value) !css.SingleBorderRadius {
	if raw_value.children.len == 1 {
		dim := pv.validate_dimension(prop_name, raw_value.children[0])!
		return [dim, dim]
	} else if raw_value.children.len != 3 {
		return ast.NodeError{
			msg: 'invalid value for property "${prop_name}"'
			pos: raw_value.pos
		}
	}

	dim1 := pv.validate_dimension(prop_name, raw_value.children[0])!
	slash := raw_value.children[1]
	if slash is ast.Operator {
		if slash.kind != .div {
			return ast.NodeError{
				msg: 'expecting a "/"'
				pos: slash.pos
			}
		}
	} else {
		return ast.NodeError{
			msg: 'expecting a "/"'
			pos: slash.pos()
		}
	}
	dim2 := pv.validate_dimension(prop_name, raw_value.children[2])!

	return [dim1, dim2]
}

pub fn (pv &PropertyValidator) valdiate_flex_size(prop_name string, raw_value ast.Value) !css.FlexSize {
	if raw_value.children.len != 1 {
		return ast.NodeError{
			msg: 'property "${prop_name}" can only have 1 value!'
			pos: raw_value.pos
		}
	}

	child := raw_value.children[0]
	return match child {
		ast.Number {
			val := child.value.f64()
			if val < 0 {
				return ast.NodeError{
					msg: 'value for property "${prop_name}" cannot be negative!'
					pos: child.pos
				}
			}

			val
		}
		ast.Ident {
			css.Keyword(child.name)
		}
		else {
			ast.NodeError{
				msg: 'invalid value for property "${prop_name}"'
				pos: child.pos()
			}
		}
	}
}

pub fn (pv &PropertyValidator) validate_flex_direction(prop_name string, raw_value ast.Value) !css.FlexDirection {
	if raw_value.children.len != 1 {
		return ast.NodeError{
			msg: 'property "${prop_name}" can only have 1 value!'
			pos: raw_value.pos
		}
	}

	child := raw_value.children[0]
	if child is ast.Ident {
		match child.name {
			'row' { return datatypes.FlexDirectionKind.row }
			'row-reverse' { return datatypes.FlexDirectionKind.row_reverse }
			'column' { return datatypes.FlexDirectionKind.column }
			'column-reverse' { return datatypes.FlexDirectionKind.column_reverse }
			else {}
		}
	}

	return ast.NodeError{
		msg: 'invalid value for property "${prop_name}"'
		pos: child.pos()
	}
}

pub fn (pv &PropertyValidator) validate_flex_wrap(prop_name string, raw_value ast.Value) !css.FlexWrap {
	if raw_value.children.len != 1 {
		return ast.NodeError{
			msg: 'property "${prop_name}" can only have 1 value!'
			pos: raw_value.pos
		}
	}

	child := raw_value.children[0]
	if child is ast.Ident {
		match child.name {
			'nowrap' { return datatypes.FlexWrapKind.nowrap }
			'wrap' { return datatypes.FlexWrapKind.wrap }
			'wrap-reverse' { return datatypes.FlexWrapKind.wrap_reverse }
			else {}
		}
	}

	return ast.NodeError{
		msg: 'invalid value for property "${prop_name}"'
		pos: child.pos()
	}
}

pub fn (pv &PropertyValidator) validate_flex_flow(raw_value ast.Value) !css.FlexBox {
	if raw_value.children.len == 1 {
		child := raw_value.children[0]
		if child is ast.Ident {
			return css.FlexBox{
				direction: css.Keyword(child.name)
				wrap: css.Keyword(child.name)
			}
		}

		if direction := pv.validate_flex_direction('flex-flow', ast.Value{
			children: [child]
			pos: child.pos()
		})
		{
			return css.FlexBox{
				direction: direction
			}
		} else if wrap := pv.validate_flex_wrap('flex-flow', ast.Value{
			children: [child]
			pos: child.pos()
		})
		{
			return css.FlexBox{
				wrap: wrap
			}
		}
	} else if raw_value.children.len == 2 {
		direction := pv.validate_flex_direction('flex-flow', ast.Value{
			children: [raw_value.children[0]]
			pos: raw_value.children[0].pos()
		})!
		wrap := pv.validate_flex_wrap('flex-flow', ast.Value{
			children: [raw_value.children[1]]
			pos: raw_value.children[1].pos()
		})!
		return css.FlexBox{
			direction: direction
			wrap: wrap
		}
	}

	return ast.NodeError{
		msg: 'invalid value for property "flex-flow"'
		pos: raw_value.pos
	}
}

pub fn (pv &PropertyValidator) validate_flex(raw_value ast.Value) !css.FlexBox {
	mut dimension_values := []css.DimensionValue{}
	mut number_vals := []f64{}
	mut keywords := []string{}

	for child in raw_value.children {
		match child {
			ast.Dimension {
				dimension_values << pv.validate_dimension('flex', child)!
			}
			ast.Number {
				val := child.value.f64()
				if val < 0 {
					dimension_values << val
				} else {
					number_vals << val
				}
			}
			ast.Ident {
				keywords << child.name
			}
			else {
				return ast.NodeError{
					msg: 'invalid value for property "flex"'
					pos: child.pos()
				}
			}
		}
	}

	if raw_value.children.len == 1 && number_vals.len == 1 {
		// flex-grow
		return css.FlexBox{
			grow: number_vals[0]
			shrink: 1.0
			basis: 0.0
		}
	} else if raw_value.children.len == 1 && dimension_values.len == 1 {
		return css.FlexBox{
			grow: 1.0
			shrink: 1.0
			basis: dimension_values[0]
		}
	} else if raw_value.children.len == 1 && keywords.len == 1 {
		return css.FlexBox{
			grow: 1.0
			shrink: 1.0
			basis: css.Keyword(keywords[0])
		}
	} else if raw_value.children.len == 2 && number_vals.len == 2 {
		// flex-grow and flex-shrink
		return css.FlexBox{
			grow: number_vals[0]
			shrink: number_vals[1]
			basis: 0.0
		}
	} else if raw_value.children.len == 2 && number_vals.len == 1 && dimension_values.len == 1 {
		// flex-grow and flex-basis
		return css.FlexBox{
			grow: number_vals[0]
			shrink: 1.0
			basis: dimension_values[0]
		}
	} else if raw_value.children.len == 3 {
		mut flex := css.FlexBox{
			grow: number_vals[0]
			shrink: number_vals[1]
		}
		if keywords.len == 1 {
			flex.basis = css.Keyword(keywords[0])
		} else if dimension_values.len == 1 {
			flex.basis = dimension_values[0]
		} else if number_vals.len == 3 {
			flex.basis = number_vals[2]
		} else {
			return ast.NodeError{
				msg: 'invalid value for property "flex"'
				pos: raw_value.pos
			}
		}

		return flex
	}

	return ast.NodeError{
		msg: 'invalid value for property "flex"'
		pos: raw_value.pos
	}
}

pub fn (pv &PropertyValidator) validate_font_family(raw_value ast.Value) !css.FontFamily {
	mut vals := []string{}

	for child in raw_value.children {
		match child {
			ast.Ident {
				vals << child.name
			}
			ast.String {
				vals << child.value
			}
			ast.Operator {
				if child.kind != .comma {
					return ast.NodeError{
						msg: 'unexpected operator'
						pos: child.pos
					}
				}
			}
			else {
				return ast.NodeError{
					msg: 'invalid value for property "font-family"'
					pos: child.pos()
				}
			}
		}
	}

	return vals
}

pub fn (pv &PropertyValidator) validate_font_stretch(raw_value ast.Value) !css.FontStretch {
	if raw_value.children.len != 1 {
		return ast.NodeError{
			msg: 'property "font-stretch" only expects 1 value!'
			pos: raw_value.pos
		}
	}

	child := raw_value.children[0]

	if child is ast.Ident {
		match child.name {
			'normal' {
				return datatypes.FontStretchKind.normal
			}
			'ultra-condensed' {
				return datatypes.FontStretchKind.ultra_condensed
			}
			'extra-condensed' {
				return datatypes.FontStretchKind.extra_condensed
			}
			'semi-condensed' {
				return datatypes.FontStretchKind.semi_condensed
			}
			'expanded' {
				return datatypes.FontStretchKind.expanded
			}
			'extra-expanded' {
				return datatypes.FontStretchKind.extra_expanded
			}
			'ultra-expanded' {
				return datatypes.FontStretchKind.ultra_expanded
			}
			'semi-expanded' {
				return datatypes.FontStretchKind.semi_expanded
			}
			else {
				return css.Keyword(child.name)
			}
		}
	} else if child is ast.Dimension {
		if child.unit == '%' {
			return datatypes.Percentage(child.value.f64() / 100)
		}
	}

	return ast.NodeError{
		msg: 'invalid value for property "font-stretch"'
		pos: child.pos()
	}
}

pub fn (pv &PropertyValidator) validate_font_weight(raw_value ast.Value) !css.FontWeight {
	if raw_value.children.len != 1 {
		return ast.NodeError{
			msg: 'property "font-weight" only expects 1 value!'
			pos: raw_value.pos
		}
	}

	child := raw_value.children[0]
	if child is ast.Number {
		val := child.value.int()

		if val < 1 || val > 1000 {
			return ast.NodeError{
				msg: 'Font weight must be between [1, 1000]'
				pos: child.pos
			}
		}

		return css.FontWeight(val)
	} else if child is ast.Ident {
		return css.Keyword(child.name)
	}

	return ast.NodeError{
		msg: 'invalid value for property "font-weight"'
		pos: child.pos()
	}
}
