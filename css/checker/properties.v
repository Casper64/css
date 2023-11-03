module checker

import css
import css.ast
import css.datatypes
import css.errors

pub fn (mut c Checker) validate_declarations(declarations []ast.Node) map[string]css.RawValue {
	mut style_map := map[string]css.RawValue{}

	for decl in declarations {
		match decl {
			ast.Declaration {
				if value := c.validator.validate_property(decl.property, decl.value) {
					style_map[decl.property] = css.RawValue{
						important: decl.important
						value: value
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

// seperating the property validator from the checker means that the validator
// can be extended by embedding it allowing custom properties and the ability
// to override default behaviour of css values
pub struct PropertyValidator {}

pub fn (pv PropertyValidator) validate_property(property string, raw_value ast.Value) !css.Value {
	match property {
		'color' {
			return pv.validate_color(raw_value)!
		}
		else {}
	}

	return error('unsupported property "${property}"! Check the "CAN_I_USE.md" to see a list of supported properties')
}

// `color: `
pub fn (pv PropertyValidator) validate_color(raw_value ast.Value) !css.ColorValue {
	if raw_value.children.len > 1 {
		return ast.NodeError{
			msg: 'property "color" only expects 1 value!'
			pos: raw_value.pos
		}
	}

	color_value := raw_value.children[0]
	match color_value {
		ast.Ident {
			// named color
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
				else {
					ast.NodeError{
						msg: 'unsupported function "${color_value.name}" for property "color".\n${errors.did_you_mean(valid_color_functions)}'
						pos: color_value.pos
					}
				}
			}
		}
		else {
			return ast.NodeError{
				msg: 'invalid value for property "color"!'
				pos: raw_value.pos
			}
		}
	}
}

// `rgb()`, `rgba()`
pub fn (pv PropertyValidator) validate_fn_rgb(func ast.Function) !datatypes.Color {
	mut rgbas := []u8{}

	for i, node in func.children {
		match node {
			ast.Operator {
				// `/ 80%` alpha syntax
				if node.kind == .div {
					if i + 1 == func.children.len {
						return ast.NodeError{
							msg: 'expecting an alpha value after "/"'
							pos: node.pos
						}
					} else if i + 2 != func.children.len {
						return ast.NodeError{
							msg: 'unexpected ident: expecting the alpha value to be the last argument to `rgb(a)`'
							pos: func.children[i + 2].pos()
						}
					}

					// check if next node is a percentage value
					alpha := func.children[i + 1]
					if alpha !is ast.Dimension || (alpha is ast.Dimension && alpha.unit != '%') {
						return ast.NodeError{
							msg: 'expecting a percantage value'
							pos: alpha.pos()
						}
					}
					// convert 80% to 0-255
					rgbas << u8((alpha as ast.Dimension).value.f32() / 100 * 255)
					break
				} else if node.kind != .comma {
					return ast.NodeError{
						msg: 'unexpected operator: expecting a number or alpha value'
						pos: node.pos
					}
				}
			}
			ast.Number {
				rgbas << node.value.u8()
			}
			else {
				return ast.NodeError{
					msg: 'unexpected ident'
					pos: node.pos()
				}
			}
		}
	}

	// set alpha to 100% when only given `rgb`
	if rgbas.len == 3 {
		rgbas << 255
	} else if rgbas.len != 4 {
		return ast.NodeError{
			msg: 'expecting 3 or 4 arguments to the `rgb(a)` function not "${rgbas.len}"'
			pos: func.pos
		}
	}

	return datatypes.Color{
		r: rgbas[0]
		g: rgbas[1]
		b: rgbas[2]
		a: rgbas[3]
	}
}
