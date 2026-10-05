
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| swatch-grid-view-001 | clamps-column-count | Construct with columns = 0 | The component lays out swatches into rows of at most 1 swatch each (columns treated as 1) |
| swatch-grid-view-002 | clamps-column-count | Construct with columns = -3 | The component lays out swatches into rows of at most 1 swatch each (columns treated as 1) |
| swatch-grid-view-003 | arranges-swatches-in-rows | Construct with 10 colors and columns = 4 | 3 rows are produced: 4, 4, and 2 swatches, in the same order as the input array |
| swatch-grid-view-004 | builds-hierarchy-on-init | Construct with 3 colors and columns = 8 | Immediately after construction, the row/swatch hierarchy contains exactly 1 row with exactly 3 swatches |
| swatch-grid-view-005 | replaces-colors-and-rebuilds | Construct with 5 colors, then replace them with an empty array | The row/swatch hierarchy is empty (0 rows, 0 swatches) after the call; none of the original 5 swatch elements remain anywhere in it |
| swatch-grid-view-006 | replaces-colors-and-rebuilds | Construct with 2 colors, then replace them with 6 new colors, columns unchanged at 8 | The row/swatch hierarchy contains exactly 1 row with exactly 6 swatches, none of which are the original 2 swatch instances |
| swatch-grid-view-007 | pins-container-to-edges | Construct the component and inspect its internal container's constraints | That container's top/leading/trailing/bottom anchors are each constrained equal to the corresponding anchor of the component, with no constant offset |
| swatch-grid-view-008 | uses-uniform-spacing | Construct with spacing = 10 | The internal container's spacing and every row's spacing each equal 10 |
| swatch-grid-view-009 | sizes-swatch-fixed | Construct with a swatch size of 40 by 16 and 1 color | The resulting swatch has an active width constraint of 40 and an active height constraint of 16 |
| swatch-grid-view-010 | renders-swatch-style | Construct with 1 color and inspect the resulting swatch's layer | The swatch is layer-backed with a 3pt corner radius, a background equal to the color's fill, and a border width of 0.5 |
| swatch-grid-view-011 | renders-swatch-style | Construct with 1 color, then switch the active theme from one built-in theme (e.g. a dark theme) to another | The swatch's border color changes from the old theme's border role color to the new theme's border role color; the fill is unaffected |
| swatch-grid-view-013 | renders-empty-grid | Construct with an empty color array | The view has zero rows and zero swatches immediately after construction |
| swatch-grid-view-014 | shortens-final-row | Construct with 10 colors and columns = 4 | The final row contains exactly 2 swatches (10 mod 4), fewer than a full row of 4 |
| swatch-grid-view-015 | single-row-when-columns-exceeds-count | Construct with 3 colors and columns = 8 | Exactly 1 row is produced, containing all 3 swatches, fewer than columns |
| swatch-grid-view-016 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

