
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-spacing-001 | edge-inset-default-zero | Fresh store, no `pane_spacing_top` value ever set | The top edge inset setting reads `0` |
| pane-spacing-002 | gutter-default-one-point | Fresh store, no `pane_spacing_between_columns` value ever set | The between-columns gutter setting reads `1` |
| pane-spacing-003 | settings-not-secure | Inspect whether each of the six spacing settings is marked secure/sensitive storage | Every one reports as non-secure |
| pane-spacing-004 | current-reads-live-value-per-field | Set the leading edge inset setting to `12`, then read the current spacing value | The current spacing value's `leading` equals `12` |
| pane-spacing-005 | current-populates-all-six-fields | Set all six settings to distinct nonzero values, then read the current spacing value | `top`, `leading`, `bottom`, `trailing`, `betweenColumns`, and `betweenRows` each equal the value set for that field |
| pane-spacing-006 | content-insets-maps-fields-to-edge-insets | Set edges to `top: 1, leading: 2, bottom: 3, trailing: 4` | The computed content insets equal `top: 1, left: 2, bottom: 3, right: 4` |
| pane-spacing-007 | minimum-divider-grab-fixed | Set `betweenColumns` to `0`, then to `50` | The minimum divider grab width equals `6` in both cases |
| pane-spacing-008 | divider-thickness-selects-axis-gutter | The split view is arranged with panes side by side (vertical split), `betweenColumns = 8` | The divider thickness equals `8` |
| pane-spacing-009 | divider-thickness-selects-axis-gutter | The split view is arranged with panes stacked (horizontal split), `betweenRows = 2` | The divider thickness equals `2` |
| pane-spacing-010 | divider-paint-defers-when-hairline | Gutter at its `1`pt default; observe whether the platform's own default divider painting ran when the divider is painted | The platform's own default divider painting ran, and sampling a pixel inside the divider area afterward does not show the theme's pane-backdrop color |
| pane-spacing-011 | divider-paint-fills-with-pane-backdrop | Vertical split, `betweenColumns = 10`; observe whether the platform's own default divider painting ran, then render the divider into a bitmap | The platform's own default divider painting did not run, and sampling pixels across the full divider area in the rendered bitmap shows the theme's pane-backdrop color |
| pane-spacing-012 | spacing-change-toggles-divider-style | The divider style is at its default; observe every value assigned to the divider style, then notify that spacing changed | The recorded assignments show the divider style set to a value other than its original one and then back to the original, in that order (any other-than-original intermediate value satisfies the requirement); alternatively, the hosting split-view controller observably re-reads the divider thickness after the call |
| pane-spacing-013 | spacing-change-requests-redraw | The view is not currently marked for redraw; notify that spacing changed | The view becomes marked for redraw |
| pane-spacing-014 | spacing-shared-across-windows | Two split-view instances, each arranged with panes side by side, in two different windows; change the between-columns gutter setting once | Both instances' divider thickness reflect the new value |
| pane-spacing-015 | setting-changes-persist-via-shared-store | Set the top edge inset setting to `5`, then read it back directly from the shared settings store | Returns `5`, showing the write reached the shared store rather than only a local cached value |
| pane-spacing-016 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

