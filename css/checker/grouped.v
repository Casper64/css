module checker

import css

pub fn (pv &PropertyValidator) set_grouped(prop_name string, value css.Value, mut style_map map[string]css.RawValue) bool {
	if prop_name.starts_with('background-') {
		pv.set_grouped_background(prop_name, value, mut style_map)
	} else if prop_name.starts_with('padding-') || prop_name.starts_with('margin-') {
		pv.set_grouped_margin_padding(prop_name, value, mut style_map)
	} else {
		return false
	}

	return true
}

pub fn (pv &PropertyValidator) set_grouped_background(prop_name string, value css.Value, mut style_map map[string]css.RawValue) {
	if 'background' !in style_map {
		style_map['background'] = css.RawValue{
			value: css.Background{}
		}
	}
	mut bg_val := style_map['background'].value as css.Background

	match prop_name {
		'background-color' {
			bg_val.color = value as css.ColorValue
		}
		'background-image' {
			bg_val.image = value as css.Image
		}
		else {}
	}

	style_map['background'].value = bg_val
}

pub fn (pv &PropertyValidator) set_grouped_margin_padding(prop_name string, value css.Value, mut style_map map[string]css.RawValue) {
	// extract "padding" from "padding-left"
	short_name := prop_name.all_before('-')
	if short_name !in style_map {
		style_map[short_name] = css.RawValue{
			value: css.MarginPadding{}
		}
	}

	mut mgpd_val := style_map[short_name].value as css.MarginPadding

	match prop_name.all_after('-') {
		'top' {
			mgpd_val.top = value as css.DimensionValue
		}
		'right' {
			mgpd_val.right = value as css.DimensionValue
		}
		'bottom' {
			mgpd_val.right = value as css.DimensionValue
		}
		'left' {
			mgpd_val.left = value as css.DimensionValue
		}
		else {}
	}

	style_map[short_name].value = mgpd_val
}
