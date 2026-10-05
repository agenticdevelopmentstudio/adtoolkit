
- Role: the component sets no role, label, or text alternative of its own and does not disable the chart library's default accessibility layer (the library, at the version the package depends on, defaults it on), so the plot is exposed by the library as an application region; the legend and axis tick labels are text a screen reader can reach.
- Label requirement: not satisfied — the component accepts no accessible-name input and passes no title to the chart.
- Keyboard: provided by the chart library's default accessibility layer rather than by the component — the plot is focusable and the left and right arrow keys move the tooltip between x positions; the component adds no keyboard path of its own.
- Differentiate without color: satisfied for identity when there are two or more series, because the legend and tooltip name each series (see legend-from-two-series); the lines themselves differ only by colour.
- Contrast: all colours are theme tokens, and the component performs no contrast check of its own; whether the series colours meet a minimum contrast ratio against the page background depends on the resolved token values.

