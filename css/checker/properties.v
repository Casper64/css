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
		'block-size', 'bottom', 'column-gap', 'height', 'inline-size', 'left', 'letter-spacing',
		'line-height', 'max-height', 'max-width', 'min-height', 'min-width', 'order', 'orphans',
		'perspective', 'right', 'row-gap', 'tab-size', 'text-indent', 'top', 'vertical-align',
		'widows', 'width', 'word-spacing', 'z-index' {
			return pv.validate_single_dimension_prop(property, raw_value)!
		}
		'opacity' {
			return pv.validate_alpha_value_prop(property, raw_value)!
		}
		'padding', 'margin' {
			return pv.validate_4_dim_value_prop(property, raw_value)!
		}
		'content' {
			return pv.validate_single_string(property, raw_value)!
		}
		// TODO: these values aren't used that often, check if it's faster to match them at the end of the `else` clause
		'align-content', 'align-items', 'align-self', 'all', 'appearance', 'backface-visibility',
		'box-sizing', 'caption-side', 'clear', 'cursor', 'direction', 'display', 'empty-cells',
		'float', 'forced-color-adjust', 'isolation', 'justify-content', 'justify-items',
		'justify-self', 'mix-blend-mode', 'object-fit', 'overflow-x', 'overflow-y',
		'pointer-events', 'position', 'print-color-adjust', 'resize', 'scroll-behavior',
		'table-layout', 'text-align', 'text-align-last', 'text-justify', 'text-rendering',
		'text-transform', 'text-wrap', 'touch-action', 'unicode-bidi', 'user-select', 'visibility',
		'white-space', 'word-break', 'word-wrap', 'writing-mode' {
			return pv.validate_single_keyword_prop(property, raw_value)!
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
		else {
			// handle properties with similair endings / starts
			if property.starts_with('background') {
				return pv.validate_background(property, raw_value)
			} else if property.ends_with('-color') {
				// for properties like `background-color`, or `border-left-color`
				return pv.validate_single_color_prop(property, raw_value)!
			} else if property.starts_with('margin-') || property.starts_with('padding-') {
				// for properties like `margin-left`, or `padding-top`
				return pv.valditate_margin_padding(property, raw_value)!
			} else if property.ends_with('-shadow') {
				return pv.validate_shadow(property, raw_value)!
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

pub fn (pv &PropertyValidator) valditate_margin_padding(prop_name string, raw_value ast.Value) !css.Value {
	if four_dim_endings.any(fn [prop_name] (ending string) bool {
		return prop_name.ends_with(ending)
	})
	{
		return pv.validate_single_dimension_prop(prop_name, raw_value)!
	}

	return error(pv.unsupported_property(prop_name))
}

pub fn (pv &PropertyValidator) validate_4_dim_value_prop(prop_name string, raw_value ast.Value) !css.MarginPadding {
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
		return css.MarginPadding{vals[0], vals[0], vals[0], vals[0]}
	} else if vals.len == 2 {
		return css.MarginPadding{vals[0], vals[1], vals[0], vals[1]}
	} else if vals.len == 3 {
		return css.MarginPadding{vals[0], vals[1], vals[2], vals[1]}
	} else {
		return css.MarginPadding{vals[0], vals[1], vals[2], vals[3]}
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
