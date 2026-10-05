
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `isEdgeEnabled` | Function: edge → Boolean | — (required) | Read once per toggle at panel construction, and again after every toggle, to decide each toggle's displayed state. Ownership of the underlying storage is external to this component. |
| `setEdgeEnabled` | Function: (edge, Boolean) → void | — (required) | Invoked with the toggled edge and the toggle's clicked value whenever a Tabs toggle's action fires. |
| Frame-spacing settings (top/leading/bottom/trailing) | Integer | `0` | App-wide frame-spacing inset per side, bound live to the frame-spacing control; persisted keys `pane_spacing_top`/`pane_spacing_leading`/`pane_spacing_bottom`/`pane_spacing_trailing`. |
| Gutter-spacing settings (between columns/rows) | Integer | `1` | App-wide pane-divider gutter width, bound live to the divider-spacing control; persisted keys `pane_spacing_between_columns`/`pane_spacing_between_rows`. |

