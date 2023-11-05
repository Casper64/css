module checker

const (
	pseudo_class_selectors_functions   = ['current', 'dir', 'has', 'is', 'lang', 'is', 'not',
		'nth-child', 'nth-of-type', 'nth-last-child', 'nth-of-type', 'where']
	pseudo_element_selectors_functions = ['part', 'slotted']
)

const (
	valid_color_functions = ['rgb', 'rgba', 'hsl']
	valid_units           = ['em', 'rem', 'px', 'vw', 'vh']
)

const (
	four_dim_endings = ['-left', '-top', 'right', '-bottom']
)
