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
	mut mgpd_val := (style_map[short_name] or { MarginPadding{} }) as MarginPadding

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
