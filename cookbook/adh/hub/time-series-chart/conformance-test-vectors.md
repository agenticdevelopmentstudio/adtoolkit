
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| T1 | draws-one-line-per-series, legend-from-two-series, legend-uses-series-label | three points; series `direct` ("Direct") and `fixed` ("Fixed") (test: draws one line per series with a legend naming each) | Two line paths render; the labels "Direct" and "Fixed" appear |
| T2 | series-colour-by-position, palette-tokens-with-fallback | the same two series (test: colours series by position in the fixed order) | The first line's stroke is the blue token with fallback `#2f80ff`; the second's is the orange token with fallback `#f6821f` |
| T3 | legend-from-two-series | one series only (test: shows no legend for a single series) | One line path renders and no legend element exists |
| T4 | format-applies-to-axis-and-tooltip | one series, format function that prefixes "v" (test: formats y-axis ticks with the given formatter) | At least one y-axis tick reads "v" followed by digits |
| T5 | refuses-fifth-series | five series with keys a, b, c, d, e (test: refuses more series than it has colours) | Rendering throws a range error |
| T6 | gap-for-null-value | a point with `null` for `direct` between two numeric points | The `direct` line breaks at that x; no value of zero is plotted there |
| T7 | tooltip-null-placeholder | hover the x position whose `direct` value is `null` | The tooltip shows an em dash for Direct and the formatted number for Fixed |
| T8 | height-parameter | no height given | The plot renders 240 pixels high |
| T9 | series-colour-by-position | four series | Strokes are blue, orange, violet, pink in series order |
| T10 | refuses-fifth-series | five series | The error message names a limit of 4 and a count of 5 |

