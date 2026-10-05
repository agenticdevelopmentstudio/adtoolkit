
The tab bar renders the edge-aligned tab strip for the multi-edge tabbed
view: one pill-style button per tab, laid out in a row for a top/bottom bar
or a column for a left/right bar, following the bar's own edge. It owns no
selection or ordering policy of its own — its items and selected id are
handed to it by its owner, and it reports user intent back to its owner
purely through three callbacks (select, close, reorder) so it stays
decoupled from the tabbed view's own public interface. Two helper roles live
alongside it and are described here because neither has a recipe of its own
within this file's scope: a hosted-item wrapper, which wraps a
content-hosting item's view so a click anywhere on it selects the tab, and a
tab button, the pill control that renders a title item with its own close
icon.

