
- **Corner radius**: The card's corner radius is 10pt, set once at
  construction. Neither the component itself nor the header/caption draws a
  shape of its own.
- **Padding**: The caption-to-card gap is 6pt. Inside the card, a
  standard-style row is padded 9pt above and below its content and 14pt on
  each side; a continuation-style row takes the same 9pt bottom and 14pt
  horizontal padding but 0pt of top padding, tucking it against the row
  above. The outer stack and the row area contribute 0pt of padding beyond
  their own content.
- **Font**: The caption/header text tracks the active theme's `.caption`
  text role; weight and size are not literal in this component — they come
  from the theme's `.caption` definition. The component sets no font of its
  own on row content; each row's typography belongs to its caller-supplied
  content.
- **Background**: The card's fill is the theme's `.elevatedSurface` role.
  The component (the outer view) itself has no background color or layer.
- **Foreground/Text**: The caption/header text color is the theme's
  `.secondaryText` role. The component sets no foreground color of its own
  on row content.
- **Border**: The card has no outline of its own (no stroke). Between rows,
  a 1pt hairline divider is drawn instead, inset 14pt from the leading edge
  and flush to the trailing edge, shown only where the separator-visibility
  rule computes that one is due.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere.
- **Min/Max size**: Not applicable — no explicit min/max width or height
  constraint is set. The only size constraint activated at runtime beyond
  internal layout is the component's own width matching its parent's width;
  height follows entirely from the header's and the accumulated rows'
  content.

