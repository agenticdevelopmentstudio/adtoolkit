
The Settings Split View is the base component for a topic/detail
split-pane container used throughout the settings window: a
non-collapsible sidebar of panels on the left, driven by a panel list
component, and a themed detail pane on the right that shows whichever
panel is currently selected, hosted inside a detail-pane host component.
It builds on a themed split-container base (supplying theme-aware
split-view chrome and a divider-hiding safety fix) and implements a
search-field arrow-key redirect solely to steer the sidebar search
field's Down/Up presses to sidebar-row navigation instead of moving the
text caret. A client subclasses this component and populates it during
its own setup step by adding panels.

A hosted panel MAY itself be a settings split view (see the nested split's
own recipe), in which case this component treats it as a nested split: it
unifies every nested sibling's sidebar to one content width and raises its
own detail floor so the nested content is never squeezed.

**Owns:**
- Panel storage and ordering, including optional alphabetical sorting
- An in-place back/forward navigation trail
- Sidebar sizing — draggable-and-autosaved, or content-sized and pinned
- An optional sidebar search field and its arrow-key-to-selection redirect
- Repainting the window/detail backgrounds from the active theme
- Forwarding help state to a detail-pane host component

**Delegates to:**
- The panel list — sidebar row rendering and search matching (its own
  recipe)
- The detail-pane host — the detail pane's help-button chrome (its own
  recipe)
- The panel scroll wrapper — the scroll wrapper around non-self-scrolling
  panel content (its own recipe)
- The settings window — the window-level toolbar that drives this
  component's back/forward navigation and help presentation (its own
  recipe)

This recipe documents only what this component itself declares.

