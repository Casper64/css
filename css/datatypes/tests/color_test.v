import css.datatypes
import gx

fn test_color() {
	mut c := datatypes.Color.from_hex('fff')
	assert c == datatypes.Color{255, 255, 255, 255}

	c = datatypes.Color.from_hex('fffa')
	assert c == datatypes.Color{255, 255, 255, 170}

	c = datatypes.Color.from_hex('abcdef')
	assert c == datatypes.Color{171, 205, 239, 255}

	c = datatypes.Color.from_hex('abcdef05')
	assert c == datatypes.Color{171, 205, 239, 5}
}

fn test_color_to_int() {
	assert datatypes.Color{255, 10, 32, 11}.int() == 0xff0a200b
}

fn test_compatible_with_gx() {
	c := datatypes.Color{10, 20, 30, 40}

	assert gx.Color{
		...c
	} == gx.Color{10, 20, 30, 40}
}
