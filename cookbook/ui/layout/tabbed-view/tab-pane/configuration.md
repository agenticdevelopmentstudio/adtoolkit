
Not applicable: the pane exposes no tunable, per-instance configuration
options. The edge and tab ID (set once at construction) are fixed identity,
not configuration a caller varies for behavior or appearance; every other
number that shapes the card (minimum/maximum width, minimum height,
workspace overlap, per-step recession inset, maximum stack depth, animation
duration, padding) is a compiled-in constant, never exposed as an
initializer parameter or settable property.

