# CSS Specs implementation progress (Parser)

- [X] Comments

## Selectors

- [X] Attribute Selectors (`button[type="submit"]`)
- [X] ID Selectors (`#id`)
- [X] Class Selectors (`.class`)
- [ ] Nested Selectors (yes it is actually build into CSS!)
- [X] Type Selectors `p`
- [*] Univseral Selectors (`*`)
- [X] Selector Lists `p, div, .test`
- [X] Selector combinators  `.test p`, `.test > p`

## Properties

- [X] Dimensions `100px`
- [X] Strings `before: 'test'`
- [X] Numbers: `10`
- [X] Functions: `rgb(0, 0, 0)`
- [X] Parentheses `calc(100vw - (10px + 20em))`
- [X] `!important`

## Pseudo stuff

- [X] Psuedo classes
- [X] Pseudo elements

## At-rules
- [X] `@charset`
- [ ] `@color-profile`
- [ ] `@container`
- [ ] `@counter-style`
- [ ] `@font-face`
- [ ] `@import`
- [X] `@keyframes`
- [X] `@layer`
- [X] `@media`
- [ ] `@property`