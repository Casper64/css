module checker

const (
	four_dim_endings                   = ['-left', '-top', 'right', '-bottom']
	gradient_directions                = ['left', 'top', 'right', 'bottom']
	pseudo_class_selectors_functions   = ['current', 'dir', 'has', 'is', 'lang', 'is', 'not',
		'nth-child', 'nth-of-type', 'nth-last-child', 'nth-of-type', 'where']
	pseudo_element_selectors_functions = ['part', 'slotted']
	valid_color_functions              = ['rgb', 'rgba', 'hsl']
	valid_image_fns                    = ['url', 'linear-gradient', 'radial-gradient',
		'repeating-linear-gradient', 'repeating-radial-gradient']
	valid_units                        = ['em', 'rem', 'px', 'vw', 'vh']
	vendor_prefixes                    = ['-moz-', '-webkit-', '-ms-', '-o-']
	valid_gradient_functions           = ['linear-gradient', 'radial-gradient',
		'repeating-linear-gradient', 'repeating-radial-gradient']
)
