
Not applicable: the file contains no user-facing string literals of its
own. The row's title comes from the view model's title and its caption
text comes from the caller-supplied formatter; both are values the caller
provides, so there is nothing for this component to localize itself. The
example formatters in Overview are illustrative and are not locale-aware; a
caller building a locale-correct caption should format the formatter's
output with the platform's own number/percent formatting facility rather
than raw string interpolation — this component neither performs nor
enforces that choice.

