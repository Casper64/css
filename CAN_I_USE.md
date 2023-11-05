# Can I use

Check this file to see what part of the CSS specification you can use. 
If you can't find what you're looking for the functionality is not implemented yet.

## General Features & Syntax 
Much of the CSS syntax is supported. Below are a few "newer" parts of the CSS syntax.

| Name | Supported | Remarks |
| --- | --- | --- |
| CSS variables | No | Supported in parser
| Nested rules | No | Parser: `In Progress` |
| Multiple selectors | Yes | |


## @-rules
Supported `@`-rules are parsed into rules, but it is up to you whether you apply
these rules. Since most of them require knowledge of the state of the DOM.

| @-rule | Supported | Remarks |
| --- | --- | --- |
| @charset | Yes | checker: `In Progress` |
| @color-profile | No | |
| @container | No | |
| @font-face | No | |
| @container | No | |
| @import | No | |
| @keyframes | Yes | checker: `In Progress` |
| @layer | Yes | checker: `In Progress` |
| @media | Yes | checker: `In Progress` |
| @namespace | No | |
| @page | No | |
| @property | No | |
| @supports | No | |

## Properties

| Property | Supported | Remarks |
| --- | --- | --- |
| border | No | only `-color` properties
| bottom | Yes | |
| color | Yes | |
| height | Yes | |
| left | Yes | |
| margin | Yes | only `-top`, `-left`, `-right`, `-bottom` and `margin` |
| opacity | Yes | |
| padding | Yes |  only `-top`, `-left`, `-right`, `-bottom` and `padding` |
| right | Yes | |
| top | Yes | |
| width | Yes | |

## Functions

| Function | Supported | Remarks |
| --- | --- | --- |
| calc() | No | `In progress`
| hsl(), hsla() | No | |
| rgb(), rgba() | Yes | with support for optional alpha value: `rgb(0 0 0 / 20%)` |
| var() | No | CSS variables are not supported yet