
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a (literal) | "Add:" | Row caption for the view-choice list |
| n/a (literal) | "Where:" | Row caption for the direction choice list |
| n/a (literal) | "Left" | Direction choice item |
| n/a (literal) | "Right" | Direction choice item (default selection) |
| n/a (literal) | "Above" | Direction choice item |
| n/a (literal) | "Below" | Direction choice item |
| n/a (literal) | "Cancel" | Cancel button title |
| n/a (literal) | "OK" | OK button title |

Every string above is a plain literal in source, none routed through a
localization function, so none reaches a string catalog.

Not applicable beyond the table above: each offered entry's own display
name shown in the "Add" choice list is supplied by the caller, not
hardcoded in this file, so localizing it is the caller's responsibility, not
this component's.

