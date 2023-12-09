module css

// set_grouped merges sub properties into its container property
// e.g. if `prop_name` = 'background-color':
// ```
// style_map['background'] gets set to css.Background{
//     color: value
// }
// ```
fn set_grouped(prop_name string, value Value, mut style_map map[string]Value) {
	if prop_name.starts_with('background-') {
		set_grouped_background(prop_name, value, mut style_map)
	} else if prop_name.starts_with('padding-') || prop_name.starts_with('margin-') {
		set_grouped_margin_padding(prop_name, value, mut style_map)
	} else if prop_name.starts_with('text-') {
		set_grouped_text(prop_name, value, mut style_map)
	} else if prop_name.starts_with('overflow-') {
		set_grouped_overflow(prop_name, value, mut style_map)
	} else if prop_name.starts_with('border') {
		set_grouped_border(prop_name, value, mut style_map)
	} else if prop_name.starts_with('flex') {
		set_grouped_flex(prop_name, value, mut style_map)
	} else {
		style_map[prop_name] = value
	}
}

fn set_grouped_background(prop_name string, value Value, mut style_map map[string]Value) {
	mut bg_val := (style_map['background'] or { Background{} }) as Background

	match prop_name {
		'background-color' {
			bg_val.color = value as ColorValue
		}
		'background-image' {
			bg_val.image = value as Image
		}
		else {}
	}

	style_map['background'] = bg_val
}

fn set_grouped_margin_padding(prop_name string, value Value, mut style_map map[string]Value) {
	// extract "padding" from "padding-left"
	short_name := prop_name.all_before('-')
	mut mgpd_val := (style_map[short_name] or { FourDimensions{} }) as FourDimensions

	match prop_name.all_after('-') {
		'top' {
			mgpd_val.top = value as DimensionValue
		}
		'right' {
			mgpd_val.right = value as DimensionValue
		}
		'bottom' {
			mgpd_val.right = value as DimensionValue
		}
		'left' {
			mgpd_val.left = value as DimensionValue
		}
		else {}
	}

	style_map[short_name] = mgpd_val
}

fn set_grouped_text(prop_name string, value Value, mut style_map map[string]Value) {
	mut txt_val := (style_map['text'] or { Text{} }) as Text

	match prop_name {
		'text-align' { txt_val.align = value as Keyword }
		'text-align-last' { txt_val.align_last = value as Keyword }
		'text-combine-upright' { txt_val.combine_upright = value as TextCombineUpright }
		'text-indent' { txt_val.indent = value as DimensionValue }
		'text-justify' { txt_val.justify = value as Keyword }
		'text-orientation' { txt_val.orientation = value as Keyword }
		'text-overflow' { txt_val.overflow = value as TextOverflow }
		'text-rendering' { txt_val.rendering = value as Keyword }
		'text-transform' { txt_val.transform = value as Keyword }
		'text-wrap' { txt_val.wrap = value as Keyword }
		else {}
	}

	style_map['text'] = txt_val
}

fn set_grouped_overflow(prop_name string, value Value, mut style_map map[string]Value) {
	mut overflow_val := (style_map['overflow'] or { Overflow{} }) as Overflow

	match prop_name {
		'overflow-x' { overflow_val.overflow_x = value as Keyword }
		'overflow-y' { overflow_val.overflow_y = value as Keyword }
		else {}
	}

	style_map['overflow'] = overflow_val
}

fn set_grouped_border(prop_name string, value Value, mut style_map map[string]Value) {
	mut border_val := (style_map['border'] or { Border{} }) as Border

	match prop_name {
		'border' {
			border := value as Border
			border_val.colors = border.colors
			border_val.styles = border.styles
			border_val.widths = border.widths
		}
		'border-color' {
			border_val.colors = value as BorderColors
		}
		'border-style' {
			border_val.styles = value as BorderStyles
		}
		'border-width' {
			border_val.widths = value as FourDimensions
		}
		'border-collapse' {
			border_val.collapse = value as Keyword
		}
		'border-top' {
			sb := value as SingleBorder
			border_val.colors.top = sb.color
			border_val.styles.top = sb.style
			border_val.widths.top = sb.width
		}
		'border-right' {
			sb := value as SingleBorder
			border_val.colors.right = sb.color
			border_val.styles.right = sb.style
			border_val.widths.right = sb.width
		}
		'border-bottom' {
			sb := value as SingleBorder
			border_val.colors.bottom = sb.color
			border_val.styles.bottom = sb.style
			border_val.widths.bottom = sb.width
		}
		'border-left' {
			sb := value as SingleBorder
			border_val.colors.left = sb.color
			border_val.styles.left = sb.style
			border_val.widths.left = sb.width
		}
		'border-radius' {
			border_val.radius = value as BorderRadius
		}
		else {
			if prop_name.ends_with('-color') {
				border_val.colors = get_grouped_border_color(prop_name, value, style_map)
			} else if prop_name.ends_with('-style') {
				border_val.styles = get_grouped_border_style(prop_name, value, style_map)
			} else if prop_name.ends_with('-width') {
				border_val.widths = get_grouped_border_width(prop_name, value, style_map)
			} else if prop_name.ends_with('-radius') {
				border_val.radius = get_grouped_border_radius(prop_name, value, style_map)
			}
		}
	}

	style_map['border'] = border_val
}

fn get_grouped_border_color(prop_name string, value Value, style_map map[string]Value) BorderColors {
	mut bcolor_val := BorderColors{}
	if v := style_map['border'] {
		bcolor_val = (v as Border).colors
	}

	match prop_name {
		'border-top-color' { bcolor_val.top = value as ColorValue }
		'border-right-color' { bcolor_val.right = value as ColorValue }
		'border-bottom-color' { bcolor_val.bottom = value as ColorValue }
		'border-left-color' { bcolor_val.left = value as ColorValue }
		else {}
	}

	return bcolor_val
}

fn get_grouped_border_style(prop_name string, value Value, style_map map[string]Value) BorderStyles {
	mut bstyle_val := BorderStyles{}
	if v := style_map['border'] {
		bstyle_val = (v as Border).styles
	}

	match prop_name {
		'border-top-style' { bstyle_val.top = value as BorderLineStyle }
		'border-right-style' { bstyle_val.right = value as BorderLineStyle }
		'border-bottom-style' { bstyle_val.bottom = value as BorderLineStyle }
		'border-left-style' { bstyle_val.left = value as BorderLineStyle }
		else {}
	}

	return bstyle_val
}

fn get_grouped_border_width(prop_name string, value Value, style_map map[string]Value) FourDimensions {
	mut bwidth_val := FourDimensions{}
	if v := style_map['border'] {
		bwidth_val = (v as Border).widths
	}

	match prop_name {
		'border-top-width' { bwidth_val.top = value as DimensionValue }
		'border-right-width' { bwidth_val.right = value as DimensionValue }
		'border-bottom-width' { bwidth_val.bottom = value as DimensionValue }
		'border-left-width' { bwidth_val.left = value as DimensionValue }
		else {}
	}

	return bwidth_val
}

fn get_grouped_border_radius(prop_name string, value Value, style_map map[string]Value) BorderRadius {
	mut bradius_val := BorderRadius{}
	if v := style_map['border'] {
		bradius_val = (v as Border).radius
	}

	match prop_name {
		'border-top-left-radius' { bradius_val.top_left = value as SingleBorderRadius }
		'border-top-right-radius' { bradius_val.top_right = value as SingleBorderRadius }
		'border-bottom-right-radius' { bradius_val.bottom_right = value as SingleBorderRadius }
		'border-bottom-left' { bradius_val.bottom_left = value as SingleBorderRadius }
		else {}
	}

	return bradius_val
}

fn set_grouped_flex(prop_name string, value Value, mut style_map map[string]Value) {
	mut flex_val := (style_map['flex'] or { FlexBox{} }) as FlexBox

	match prop_name {
		'flex' {
			flex := value as FlexBox
			flex_val.grow = flex.grow
			flex_val.shrink = flex.shrink
			flex_val.basis = flex.basis
		}
		'flex-flow' {
			flex := value as FlexBox
			flex_val.direction = flex.direction
			flex_val.wrap = flex.wrap
		}
		'flex-direction' {
			flex_val.direction = value as FlexDirection
		}
		'flex-grow' {
			flex_val.grow = value as FlexSize
		}
		'flex-shrink' {
			flex_val.shrink = value as FlexSize
		}
		'flex-wrap' {
			flex_val.wrap = value as FlexWrap
		}
		else {}
	}

	style_map['flex'] = flex_val
}
