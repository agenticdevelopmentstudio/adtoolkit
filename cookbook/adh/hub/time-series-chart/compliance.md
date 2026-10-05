
| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy & Data |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`screen-reader-support` is `partial`: the component adds no accessible name,
text alternative, or table alternative for the plot; only the chart library's
default accessibility layer (focusable region, arrow-key tooltip navigation)
exposes the data beyond the visual chart and hover tooltip. `contrast-ratio` is `partial`: all
colours are theme tokens whose resolved values cannot be determined from the
component. `string-externalization` is `partial`: the only fixed literal is the
tooltip's em dash, and every other string comes from the caller.
`data-minimization` passes: the component only draws what it is given and keeps
nothing. `separation-of-concerns` passes: `time-series-chart.tsx` only
presents points and series supplied by the caller, holding no data fetching,
aggregation, or state. `unit-test-coverage` is `partial`: `timeSeriesChart.test.tsx`
covers one line per series with a legend naming each, colouring by position,
no legend for a single series, formatting y-axis ticks, and refusing a fifth
series; the null gap, the tooltip placeholder, and the default height are not
yet asserted by a test.

