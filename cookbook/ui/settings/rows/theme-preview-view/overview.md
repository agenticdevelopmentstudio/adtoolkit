
The Theme Preview View is a view, confined to a single, serialized execution
context, that answers "what will this theme look like?" without switching to
it first. Per its own description, it is a live sample of a color theme
drawn as the app's own UI rather than as a row of color chips: window chrome
and type, a sidebar with a selected row, form controls, status badges, the
16 ANSI swatches, and a terminal that honors the theme's terminal font,
padding and cursor overrides. Every sample is built from a real component's
shape — a list row really is a rounded selection fill under the
selection-text role, a badge really is success/warning/danger/info — so the
preview exercises the same semantic-palette role lookups the rest of the app
uses, rather than a parallel, idealized set of demo colors.

The view starts empty; calling the show operation with a color theme
resolves a semantic palette and fully rebuilds five sample cards (chrome,
list with its tab strip, controls, status badges, terminal) plus an embedded
swatch grid of the theme's 16 ANSI colors. It composes the sibling Swatch
Grid View ingredient directly rather than re-implementing a swatch grid, but
implements its own private, structurally similar "badge" capsule for the
status row rather than reusing the shared Badge ingredient (see Design
Decisions).

