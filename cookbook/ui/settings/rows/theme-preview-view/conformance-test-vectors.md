
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-preview-view-001 | container-pinning | Construct the view and inspect its structure | The component has exactly one direct content container, whose top/leading/trailing/bottom edges equal the component's own with no offset |
| theme-preview-view-002 | empty-initial-state | Construct the component with no theme argument | The container holds no samples and the component's background is unset |
| theme-preview-view-004 | show-teardown-and-rebuild | Call show(themeA), note the 6 samples, then call show(themeB) | None of the original 6 sample instances remain in the container; a fresh 6 are present |
| theme-preview-view-005 | self-background-paint | Call show(theme) | The component's background color equals the resolved palette's window-background role color for that theme |
| theme-preview-view-006 | card-order | Call show(theme) and inspect the container's contents | Exactly 6 items, in order: chrome, list, controls, status, terminal, swatch grid |
| theme-preview-view-007 | card-width-stretch | Call show(theme) inside a wide host and inspect sizing | Each of the first 5 samples is sized to the container's own width |
| theme-preview-view-008 | card-minimum-width | Call show(theme) and inspect sizing on each of the 5 sample-card boxes | Each has an enforced minimum width of 280pt |
| theme-preview-view-009 | card-content-insets | Inspect the chrome card's content layout after show(theme) | Content is inset 10pt from the top, 12pt from the leading edge, 10pt from the bottom, and constrained to at most 12pt from the trailing edge |
| theme-preview-view-010 | chrome-title | Call show(theme) and read the chrome card's first label | Text is "Window Title", color equals the palette's primary-text role color, font equals the palette's title-role font |
| theme-preview-view-011 | chrome-body-and-caption | Read the chrome card's second and third labels | "Body text in the body font." in primary-text/body; "Secondary caption text" in secondary-text/caption |
| theme-preview-view-012 | chrome-controls-row | Read the chrome card's controls row | Two pills, "Button" (fill accent, text on-accent-text) and "Selected" (fill selection, text selection-text), both button font, row spacing 8 |
| theme-preview-view-013 | chrome-divider | Inspect the chrome card's hairline element | Its thickness is 1pt, its color equals the palette's divider role color, and its width equals the card's width minus 24pt |
| theme-preview-view-014 | chrome-outlined-panel | Inspect the chrome card's inner panel | 8pt corner radius, fill elevated-surface, 1pt border outline, containing a "Panel · outline" label in tertiary-text/caption |
| theme-preview-view-015 | list-tab-strip | Read the list card's tab row | Three pills "Notes"/"Chat"/"Terminal"; "Notes" fill elevated-surface text primary-text, the other two fill surface text secondary-text; 4pt spacing |
| theme-preview-view-016 | list-row-set | Read the list card's rows in order | ("Release notes","Yesterday",unselected), ("Design review","2 days ago",selected), ("Scratch","Last week",unselected) |
| theme-preview-view-017 | selected-list-row-style | Inspect the "Design review" row | Background selection, 5pt corner radius, both labels colored selection-text |
| theme-preview-view-018 | unselected-list-row-style | Inspect the "Release notes" row | Background transparent, title primary-text, detail tertiary-text |
| theme-preview-view-019 | list-row-content-layout | Inspect any row's label layout | Title leading offset 8, detail trailing offset -8, both centered vertically, detail's leading >= title's trailing + 8 |
| theme-preview-view-020 | controls-text-field-pair | Read the controls card's two fields | "Typed text" in primary-text, "Placeholder" in placeholder-text; both control-background fill, 5pt corner radius, 1pt border outline, equal width, 8pt spacing |
| theme-preview-view-021 | controls-checkbox-line | Read the controls card's third element | Text "☑︎ Enabled    ☐ Disabled", color secondary-text, font body |
| theme-preview-view-022 | status-badge-set | Read the status card's badges in order | "Success"(success), "Warning"(warning), "Error"(danger), "Info"(info); row spacing 6 |
| theme-preview-view-023 | status-badge-style | Inspect the "Success" badge's rendering | 5pt corner radius, background = success color at 22% alpha, border 1pt = success color at 55% alpha, text = success color at full opacity, caption-role font |
| theme-preview-view-024 | terminal-box-background | Inspect the terminal card's box | Fill = the palette's window-background role color, 1pt border = the palette's border role color |
| theme-preview-view-025 | terminal-appearance-resolution | Call show(theme) where the theme's terminal settings override font/padding/cursor | The terminal sample's font, insets, and caret shape match the theme's resolved terminal-appearance values, not the app's stored defaults |
| theme-preview-view-026 | terminal-sample-content | Read the terminal card's content | Line 1: "user@mac ~ % ls" (primary-text) + caret; line 2: "Documents" (accent) and "README.md" (secondary-text), 10pt apart, 2pt below line 1 |
| theme-preview-view-027 | terminal-content-insets | Set a theme with a terminal leading padding of 40 and call show(theme) | The terminal content's leading offset from the box is 40, not the 10pt default |
| theme-preview-view-028 | cursor-shape | Set the theme's terminal cursor shape to bar and call show(theme) | The caret is 2pt wide, the resolved terminal font's cell height tall (point size plus 3, unchanged by the bar shape), filled with the palette's cursor role color |
| theme-preview-view-029 | ansi-swatch-grid | Call show(theme) and inspect the 6th item in the container | It is a swatch grid constructed with the palette's 16 ANSI colors and 8 columns |
| theme-preview-view-030 | semantic-palette-derivation | Call show(themeA) then show(themeB) with two themes differing only in their role overrides | Every sample-card color equals what the palette resolves for themeB's role overrides (roles neither theme overrides may equal the themeA value; only an override-driven mismatch fails the vector) |
| theme-preview-view-031 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

