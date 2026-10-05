
- **Corner radius**: None. No corner radius is set anywhere in this component.
- **Padding**: None set directly. Every top-level element (the root, the content view, the placeholder, loading, system-preview, and unavailable branches) fills all available width and height with no additional inset; the sole internal spacing is the placeholder's own 12pt gap between its icon and message.
- **Font**: The text editor's font is the theme's code font role, resolved from the environment theme. The placeholder message uses the theme's heading font role. The placeholder icon is a literal 48pt icon size, not a theme font role, so unlike the message it does not scale with the theme's text-size preference.
- **Background**: No background is set directly by this component on any of its own views; the mounted editors and the system preview paint their own backgrounds (the editor's derived from the theme's window-background role).
- **Foreground/Text**: Placeholder icon — theme tertiary-text role. Placeholder message — theme secondary-text role. The editor's text, cursor, selection, and syntax colors all come from the theme's editor palette (see Design Decisions and Platform Notes).
- **Border**: None specified.
- **Shadow**: None specified.
- **Min/Max size**: Filling all available width and height is applied at every level (the root, the content view, each display-state branch, and the cached-editor container), so the pane always expands to fill its container; no minimum width or height is set anywhere.

