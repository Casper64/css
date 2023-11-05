# CSS Parser

The aim of this module is to serve as an intermediate stage in graphics rendering
by supporting CSS as styling language. Checkout [this]() module I made where I 
render XML documents with CSS.

It parses a CSS file and returns a list of rules. These rules are sorted by their specificity,
so the programmer only needs to implement a way to render the rules.

## Example
TODO: update example

main.css
```css
#what {
    color: red;
}

#id, .test {
    color: green;
}
```
main.v
```v
module main

import css
import css.util as css_util

fn main() {
    rules := css_util.parse_stylesheet('main.css')!
    println('All rules:')
    println(rules)
}
```
Will give the output
```
All rules:
[css.Rule{
    selector: css.Selector{
        classes: ['test']
    }
    declarations: {
        'color': css.Value(
            css.Color('green')
        )
    }
}, css.Rule{
    selector: css.Selector{
        id: 'what'
    }
    declarations: {
        'color': css.Value(
            css.Color('red')
        )
    }
}, css.Rule{
    selector: css.Selector{
        id: 'id'
    }
    declarations: {
        'color': css.Value(
            css.Color('green')
        )
    }
}]
```

Now if you want to find the styles for the element `<p id="what" class="test"></p>`
you must find the matching rules and apply their styles.

```v
// representation of the selectors of our element
element_selector := [css.Id('what'), css.Class('test')]
// get all the rules that match our selector
matching_rules := rules.filter(|rule| rule.matches(element_selector))
// build a map of styles from our matching rules
styles := matching_rules.get_styles(matching_rules)

println('Resulting styles for `<p id="what" class="test"></p>`:')
println(styles)
```
Output:
```
Resulting styles for `<p id="what" class="test"></p>`:
{
    'color': css.Value(
        css.Color('red')
    )
}
```

If you are confused why the resulting color is `red` please referer to 
[CSS specificity](https://developer.mozilla.org/en-US/docs/Web/CSS/Specificity).

## Tests

Run all tests with `v test .`

### Runnining individual checks
```bash
v run css/parser/tests/test_program.v css/parser/tests/file.css
```

## Property Types

A list of properties and their types. Some property names start with `-`, this means
that all css properties with this ending have the same type.

For example the `-color` property has the type `css.ColorValue`, so the property `border-color`
and `outline-color` both have the type `css.ColorValue`.

| Property | Type(s) |
| --- | --- |
| background | `css.Background` |
| bottom | `css.DimensionValue` |
| color | `css.ColorValue` |
| -color | `css.ColorValue` |
| height | `css.DimensionValue `|
| left | `css.DimensionValue `|
| margin | `css.MarginPadding` |
| margin-bottom | `css.DimensionValue `|
| margin-left | `css.DimensionValue `|
| margin-right | `css.DimensionValue `|
| margin-top | `css.DimensionValue `|
| opacity | `css.AlphaValue` |
| padding | `css.MarginPadding` |
| padding-bottom | `css.DimensionValue `|
| padding-left | `css.DimensionValue `|
| padding-right | `css.DimensionValue `|
| padding-top | `css.DimensionValue `|
| right | `css.DimensionValue `|
| top | `css.DimensionValue `|
| width | `css.DimensionValue `|
