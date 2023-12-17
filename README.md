# CSS Parser
> **Note:**
> This CSS parser is not suited for production yet and the API will change in the future!


The aim of this module is to serve as an intermediate stage in graphics rendering
by supporting CSS as styling language.

It parses a CSS file and returns a list of rules. These rules are sorted by their specificity,
so the programmer only needs to implement a way to render the rules.

**Acknowledgement:**
A lot of inpsiration (and some code) is taken from the V compiler.

## Features

- 100% Written in V
- Parser can parse `bootstrap.min.css` without errors
- Parser and checker produce errors and warnings
- Rules are sorted by CSS Specificity
- Property validator (checker stage) can be embedded to handle custom properties

### TODO

- [ ] Implement more properties, functions and CSS datatypes.
- [ ] CSS Animations, `@keyframe` rules
- [ ] CSS Variables, probably will have to rely on a combination using the DOM
- [ ] Optimizations: store rules in a B+ tree by specificity, merge styles etc.
- [ ] Minifier

## Project structure

The `css` folder follows a similair directory structure as the V compiler.

The compiler stage is as follows: `lexer` produces tokens -> `parser` produces AST -> `checker` 
validates the AST and transforms it to usable structs and sumtypes.

## Usage Example

Run the example:
```v
v run examples/simple.v
```

If you are confused why the resulting color is `red` please referer to 
[CSS specificity](https://developer.mozilla.org/en-US/docs/Web/CSS/Specificity).

The `css/tests` folder also contains examples on how properties can be used.

## Tests

Run all tests with `v test .`, the tests in `css/gen` should fail.

### Runnining individual checks
```bash
v run css/parser/tests/test_program.v css/parser/tests/file.css
```
You can swap out 'parser' for 'checker'

## API

### Properties

A list of properties and their types. Some property names start with `-`, this means
that all CSS properties with this ending have the same type.

See [types.v](css/types.v) and [properties.v](css/properties.v) to see
the exact specification of each struct/sumtype.

| Type | Properties | Remarks |
| --- | --- | --- |
| `AlphaValue`| 'opacity' | |
| `Background`| 'background' | struct containing all `background-` properties |
| `Border` | 'border' | struct containing all `border-` properties | 
| `BorderColors` | 'border-color' | struct containing all 4 colors for each border side, will be merged into `Border` |
| `BorderRadius` | 'border-radius' | struct containing the radius for each corner, will be merged into `Border` |
| `BorderStyles` | 'border-style' | struct containing all styles for each border, will be merged into `Border` |
| `ColorValue` | 'color' | A sumtype representing a color value, each property ending with `-color` will be this type. |
| `DimensionValue` | 'block-size', 'bottom', 'column-gap', 'flex-basis', 'height', 'inline-size', 'left','letter-spacing' 'line-height', 'max-height', 'max-width', 'min-height', 'min-width', 'order', 'orphans', 'perspective', 'right', 'row-gap', 'tab-size', 'text-indent', 'top', 'vertical-align', 'widows', 'width', 'word-spacing', 'z-index' | A sumtype representing properties/values that represent a dimension/length, e.g. `10px`, or `50%`. |
| `Font` | 'font' | struct containing all `font-` properties |
| `FontFamily` | 'font-family' | will be merged into 'font' |
| `FontStretch` | 'font-stretch' | a sumtype containing the possible font-stretch properties, will be merged into 'font' |
| `FontWeight` | 'font-weight' | will be merged into 'font' |
| `FlexBox` | 'flex' | struct containg all `flex-` properties. |
| `FlexDirection` | 'flex-direction' | will be merged into 'flex' |
| `FlexSize` | 'flex-grow', 'flex-shrink' | will be merged into 'flex' |
| `FlexWrap` | 'flex-wrap' | A sumtype containg the possible flex-wrap types, will be merged into 'flex' |
| `FourDimensions` | 'padding', 'margin', 'border-width' | A struct containing 4 `DimensionValue` fields for top, right, bottom and left |
| `Image` | 'background-image' | A sumtype holding the different values for the `image` CSS datatype |
| `Keyword` | 'align-content', 'align-items', 'align-self', 'all', 'appearance', 'backface-visibility', 'border-collapse', 'box-sizing', 'caption-side', 'clear', 'cursor', 'direction', 'display', 'empty-cells', 'float', 'forced-color-adjust', 'isolation', 'justify-content', 'justify-items', 'justify-self', 'mix-blend-mode', 'object-fit', 'overflow-x', 'overflow-y', 'pointer-events', 'position', 'print-color-adjust', 'resize', 'scroll-behavior', 'table-layout', 'text-align', 'text-align-last', 'text-justify', 'text-rendering', 'text-transform', 'text-wrap', 'touch-action', 'unicode-bidi', 'user-select', 'visibility', 'white-space', 'word-break', 'word-wrap', 'writing-mode' | A type alias for string representing a CSS keyword like `inherit` |
| `Overflow` | 'overflow' | A struct containing the properties 'overflow-x' and 'overflow-y' |
| `ShadowValue` | 'box-shadow', 'text-shadow' | A struct containing all properties for a CSS shadow |
| `Text` | 'text' | A struct containing all text CSS properties, starting with `text-` |
| `TextCombineUpright` | 'text-combine-upright' | See MDN reference [here](https://developer.mozilla.org/en-US/docs/Web/CSS/text-combine-upright) section about `digits`. Will be merged into `Text` |
| `TextOverflow` | 'text-overflow' | Sumtype of `Keyword` and a `string`, the string type will represent the ellipsis text specified by the user, will be merged into `Text` |

### Functions

See [functions.v](css/functions.v) for the exact specifications.

| Type | Function | Remarks |
| --- | --- | --- |
| `Gradient` | 'linear-gradient', 'radial-gradient', 'repeating-linear-gradient', 'repeating-radial-gradient' | Used as datatype for each property that can have a gradient like 'background-image' |
| `Url` | 'url', 'src' | The type of url is defined in the `UrlKind` enum |

### Datatypes

See [datatypes.v](css/datatypes//datatypes.v) for a representation of currently supported CSS Datatypes.
