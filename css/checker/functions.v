module checker

import css
import css.ast
import css.datatypes

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
