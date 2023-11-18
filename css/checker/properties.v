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
					// group grouped properties, TODO: think about !important when grouping?
					was_grouped_value := c.validator.set_grouped(prop_name, value, mut
						style_map)
					if !was_grouped_value {
						// use normal property name to include browser prefix
						style_map[decl.property] = css.RawValue{
							important: decl.important
							value: value
						}
					}
				} else {
					if err is ast.NodeError {
						c.error_with_pos(err.msg(), err.pos)
					} else {
						c.error_with_pos(err.msg(), decl.pos)
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

pub fn (pv &PropertyValidator) validate_property(property string, raw_value ast.Value) !css.Value {
	// TODO: grouped properties e.g. `background: `
	match property {
		'color' {
			return pv.validate_single_color_prop(property, raw_value)!
		}
		'bottom', 'height', 'left', 'letter-spacing', 'line-height', 'max-height', 'max-width',
		'min-height', 'min-width', 'right', 'text-indent', 'top', 'width', 'word-spacing',
		'z-index' {
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
		'align-content', 'align-items', 'align-self', 'all', 'backface-visibility', 'cursor',
		'display', 'float', 'justify-content', 'justify-items', 'justify-self', 'pointer-events',
		'position', 'scroll-behavior', 'text-justify', 'text-overflow', 'text-transform',
		'user-select', 'vertical-align', 'visibility', 'white-space', 'word-break', 'word-wrap',
		'writing-mode' {
			return pv.validate_single_keyword_prop(property, raw_value)!
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
				pos: raw_value.pos
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
				pos: raw_value.pos
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
		else {
			return error(pv.unsupported_property(prop_name))
		}
	}
}

pub fn (pv &PropertyValidator) validate_image(prop_name string, raw_value ast.Value) !css.Image {
	for item in raw_value.children {
		match item {
			ast.Function {
				if item.name.ends_with('-gradient') {
					return pv.validate_fn_gradients(prop_name, item.name, item)!
				}
			}
			else {}
		}
	}

	return error(pv.unsupported_property(prop_name))
}
