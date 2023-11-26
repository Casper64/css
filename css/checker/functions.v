module checker

import css
import css.ast
import css.datatypes
import css.errors

// `rgb()`, `rgba()`
pub fn (pv &PropertyValidator) validate_fn_rgb(func ast.Function) !datatypes.Color {
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
							msg: 'expecting a percentage value'
							pos: alpha.pos()
						}
					}
					// convert 80% to 0-255
					rgbas << u8((alpha as ast.Dimension).value.f64() / 100 * 255)
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
			// TODO: calc & css variables
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
			msg: 'expecting 3 or 4 arguments for function `rgb(a)` not "${rgbas.len}"'
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

pub fn (pv &PropertyValidator) validate_fn_url(fn_name string, raw_value ast.Function) !css.Url {
	if raw_value.children.len == 0 || raw_value.children.len > 2 {
		return ast.NodeError{
			msg: 'the function "${fn_name}" expects 1 or 2 arguments'
			pos: raw_value.pos
		}
	}

	mut url := css.Url{}

	first_val := raw_value.children[0]
	if first_val is ast.String {
		url.value = first_val.value
	} else if first_val is ast.Hash {
		url.value = first_val.value
		url.kind = .element
		return url
	} else {
		return ast.NodeError{
			msg: 'invalid value for function "${fn_name}"'
			pos: first_val.pos()
		}
	}

	if url.value[0] == `#` {
		url.kind = .element
		url.value = url.value[1..]
	} else if url.value.starts_with('data:') {
		url.kind = .data
	} else if url.value.starts_with('http') {
		url.kind = .link
	} else {
		url.kind = .file
	}

	return url
}

pub fn (pv &PropertyValidator) validate_fn_gradients(prop_name string, gradient_name string, raw_value ast.Function) !css.Gradient {
	if raw_value.children.len < 2 {
		return ast.NodeError{
			msg: 'the function "${gradient_name}" expects at least 2 arguments'
			pos: raw_value.pos
		}
	}

	mut gradient := css.Gradient{}
	gradient.kind = match gradient_name {
		'linear-gradient' {
			.linear
		}
		'radial-gradient' {
			.radial
		}
		'repeating-linear-gradient' {
			.repeating_linear
		}
		'repeating-radial-gradient' {
			.repeating_radial
		}
		else {
			return ast.NodeError{
				msg: 'expecting a gradient function not "${gradient_name}"\n${errors.did_you_mean(valid_gradient_functions)}'
				pos: raw_value.pos
			}
		}
	}

	mut color_count := 0
	for i := 0; i < raw_value.children.len; {
		mut errored := false
		mut is_direction := false

		mut gradient_color := ?css.ColorValue(none)
		mut gradient_size := ?css.DimensionValue(none)

		mut j := i
		// this inner loop processes children until a "," is reached
		for j < raw_value.children.len {
			child := raw_value.children[j]
			j++

			if child is ast.Operator && child.kind == .comma {
				break
			}

			// skip until the next comma if an error has occured
			if errored {
				continue
			}

			match child {
				ast.Ident {
					if child.name == 'to' {
						if gradient.gradient_values.len > 0 {
							// gradient(red, to left, green)
							pv.error_with_pos('unexpected ident "to": only the first gradient value can be a direction',
								child.pos)
							errored = true
							continue
						} else if is_direction {
							// gradient(to to)
							pv.error_with_pos('expecting a direction after "to".\n${errors.did_you_mean(gradient_directions)}',
								child.pos)
							errored = true
							continue
						} else {
							is_direction = true
						}
					} else if child.name in gradient_directions {
						if gradient.gradient_values.len > 0 {
							// gradient(red, to left, green)
							pv.error_with_pos('unexpected ident "${child.name}": only the first gradient value can be a direction',
								child.pos)
							errored = true
							continue
						} else if !is_direction {
							// gradient(right, )
							pv.error_with_pos('expecting the keyword "to" before a direction.',
								child.pos)
							errored = true
						} else {
							match child.name {
								'top' { gradient.directions.set(.top) }
								'left' { gradient.directions.set(.left) }
								'right' { gradient.directions.set(.right) }
								'bottom' { gradient.directions.set(.bottom) }
								else {}
							}
						}
					} else {
						// gradient(red green)
						if gradient_color != none {
							pv.error_with_pos('you can only have 1 color per gradient value',
								child.pos)
							errored = true
							continue
						} else {
							gradient_color = pv.validate_single_color_prop(gradient_name,
								ast.Value{
								pos: child.pos
								children: [child]
							}) or {
								if err is ast.NodeError {
									pv.error_with_pos(err.msg(), err.pos)
								}
								errored = true
								continue
							}
							color_count++
						}
					}
				}
				ast.Hash {
					// gradient(#aaa #bbb)
					if gradient_color != none {
						pv.error_with_pos('you can only have 1 color per gradient value',
							child.pos)
						errored = true
						continue
					} else {
						gradient_color = pv.validate_single_color_prop(gradient_name,
							ast.Value{
							pos: child.pos
							children: [child]
						}) or {
							if err is ast.NodeError {
								pv.error_with_pos(err.msg(), err.pos)
							}
							errored = true
							continue
						}
						color_count++
					}
				}
				ast.Dimension {
					// gradient(5px 4px)
					if gradient_size != none {
						pv.error_with_pos('you can only have 1 dimension per gradient value',
							child.pos)
						errored = true
						continue
					} else if gradient_color == none {
						// gradient(10px red)
						pv.error_with_pos('expecting a color before a dimension value',
							child.pos)
						errored = true
						continue
					} else {
						gradient_size = pv.validate_single_dimension_prop(gradient_name,
							ast.Value{
							pos: child.pos
							children: [child]
						}) or {
							if err is ast.NodeError {
								pv.error_with_pos(err.msg(), err.pos)
							}
							errored = true
							continue
						}
					}
				}
				else {}
			}
		}
		i = j

		if !errored {
			// gradient(to, )
			if is_direction && int(gradient.directions) == 0 {
				pv.error_with_pos('expecting a direction after "to".\n${errors.did_you_mean(gradient_directions)}',
					raw_value.children[i - 1].pos())
				continue
			}

			if color := gradient_color {
				gradient.gradient_values << css.GradientValue{
					color: color
					size: gradient_size
				}
			}
		}
	}

	if color_count < 2 {
		return ast.NodeError{
			msg: 'expecting at least 2 color values in a gradient function'
			pos: raw_value.pos
		}
	}

	return gradient
}
