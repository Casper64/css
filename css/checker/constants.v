module checker

const four_dim_endings = ['-left', '-top', 'right', '-bottom']
const gradient_directions = ['left', 'top', 'right', 'bottom']
const pseudo_class_selectors_functions = ['current', 'dir', 'has', 'is', 'lang', 'is', 'not',
	'nth-child', 'nth-of-type', 'nth-last-child', 'nth-of-type', 'where']
const pseudo_element_selectors_functions = ['part', 'slotted']
const valid_color_functions = ['rgb', 'rgba', 'hsl']
const valid_image_fns = ['url', 'linear-gradient', 'radial-gradient', 'repeating-linear-gradient',
	'repeating-radial-gradient']
const valid_units = ['em', 'rem', 'px', 'vw', 'vh']
const vendor_prefixes = ['-moz-', '-webkit-', '-ms-', '-o-']
const valid_gradient_functions = ['linear-gradient', 'radial-gradient', 'repeating-linear-gradient',
	'repeating-radial-gradient']
