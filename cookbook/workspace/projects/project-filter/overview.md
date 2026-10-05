
This component is the single case-insensitive substring matcher used
everywhere a project list or a file-tree popover is searched. It exposes
two operations, deliberately routed through the same underlying scan so
neither can drift from the other: finding ranges, which returns every
case-insensitive occurrence of a query string inside a piece of text as a
list of position/length pairs, and checking a match, which decides
whether a repository record survives a search by checking whether the
query appears in its name or its path. The design's own rationale is that
keeping both answers on one code path means the characters a row
highlights can never disagree with the reason that row survived the
filter. It is consumed by two callers: the project browser's filter step,
which filters the project tree and bolds matched characters in each row's
label, and a breadcrumb's file-tree popover, which does the same for its
own rows.

