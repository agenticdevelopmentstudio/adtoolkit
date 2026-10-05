
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `detailMinimumThickness` | number (overridable) | `400` | Floor on the detail pane's minimum thickness. |
| `sidebarAutosaveName` | string, optional (overridable) | `"ComposableSettings.RootSidebar"` | Persistence key used when the content-sized-sidebar flag is `false`. |
| `contentSizedSidebar` | boolean (overridable) | `false` | `true` pins the sidebar to its content width and disables dragging/persistence; `false` keeps the draggable, persisted band. |
| `minimumSidebarWidthOverride` | number, optional | none | External floor for a content-sized sidebar's width, set by a parent split to unify nested siblings. |
| `sidebarTitle` | string, optional | none | Header title shown above the sidebar's panel list. |
| `showsSidebarSearch` | boolean | `false` | Whether the sidebar leads with a search field; read once, during the view's load step. |
| `sortsPanelsByTitle` | boolean | `false` | Whether the replace/add operations alphabetize panels (within section) instead of keeping supplied order. |
| `showsInlineHelpButton` | boolean | `true` | Whether the detail pane's own host component draws its help button. |
| `helpPresenter` | help-presenting reference, optional | none | Where help content and visibility are shown; forwarded to the detail-pane host's help presenter. |
| `listViewController` | panel list component | a stock panel list | The sidebar component; injectable at construction. |

