import css
import css.datatypes
import css.pref
import css.util as css_util

const preferences = &pref.Preferences{}

fn test_url_element() {
	rules := css_util.parse_stylesheet_from_text('.t { background-image: url(#element); }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'background': css.Background{
			image: css.Url{
				kind: .element
				value: 'element'
			}
		}
	}
}

fn test_url_data() {
	rules := css_util.parse_stylesheet_from_text('.t { background-image: url(data:image/png;base64,); }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'background': css.Background{
			image: css.Url{
				kind: .data
				value: 'data:image/png;base64,'
			}
		}
	}
}

fn test_url_link_http() {
	rules := css_util.parse_stylesheet_from_text('.t { background-image: url( http://a.com/image.png); }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'background': css.Background{
			image: css.Url{
				kind: .link
				value: 'http://a.com/image.png'
			}
		}
	}
}

fn test_url_file() {
	rules := css_util.parse_stylesheet_from_text('.t { background-image: url(myFont.woff); }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'background': css.Background{
			image: css.Url{
				kind: .file
				value: 'myFont.woff'
			}
		}
	}
}

fn test_fallback() {
	rules := css_util.parse_stylesheet_from_text('.t { background-image: url("image.png"), pointer; }',
		preferences)!
	styles := rules.get_styles()

	assert styles == {
		'background': css.Background{
			image: css.Url{
				kind: .file
				value: 'image.png'
			}
		}
	}
}
