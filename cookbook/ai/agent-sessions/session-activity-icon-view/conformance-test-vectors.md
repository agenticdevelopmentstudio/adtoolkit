
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| activity-icon-001 | fixed-glyph-size | Any constructed instance | Both the width and height constraints resolve to exactly 13pt |
| activity-icon-002 | horizontal-compression-resistance | Any constructed instance, placed in a horizontally-constrained stack layout | The component's horizontal compression resistance is at maximum; it does not shrink below 13pt |
| activity-icon-003 | state-based-symbol-selection | Constructed with activity = working, isSummarizing = true | The glyph shown is the sparkle glyph, not the double-arrow glyph |
| activity-icon-003b | state-based-symbol-selection | Constructed with activity = waiting, isSummarizing = false | The glyph shown is the circled-exclamation-mark glyph |
| activity-icon-003c | state-based-symbol-selection | Constructed with activity = idle, isSummarizing = false | The glyph shown is the filled-dot glyph |
| activity-icon-003d | state-based-symbol-selection | Constructed with activity = working, isSummarizing = false | The glyph shown is the double-arrow glyph |
| activity-icon-004 | idle-visibility-suppression | Constructed with activity = idle, isSummarizing = false | Hidden |
| activity-icon-004b | idle-visibility-suppression | Constructed with activity = idle, isSummarizing = true | Visible |
| activity-icon-005 | state-based-tint | Theme applied with activity = waiting, isSummarizing = false | The glyph is filled with the theme's warning color |
| activity-icon-005b | state-based-tint | Theme applied with activity = idle, isSummarizing = false | The glyph is filled with the theme's tertiary text color |
| activity-icon-005c | state-based-tint | Theme applied with activity = working, isSummarizing = false | The glyph is filled with the theme's accent color |
| activity-icon-005d | state-based-tint | Theme applied with isSummarizing = true (any activity) | The glyph is filled with the theme's accent color |
| activity-icon-006 | pre-theme-tint-default | Newly constructed instance, no theme applied yet | The glyph is filled with the system's tertiary label color |
| activity-icon-007 | symbol-layer-distinction | Theme applied with activity = waiting | Sampling the rendered raster at the glyph's center (the exclamation mark) yields a pixel outside the fill's solid color (e.g. transparent or antialiased against the surrounding fill), distinct from a sample taken on the surrounding ring — the tint did not collapse both layers into one flat silhouette |
| activity-icon-008 | unresolvable-symbol-fallback | The platform's icon-lookup mechanism intercepted (e.g. via a test double substituted for the system icon lookup, since the source exposes no injectable seam for it) to return no image for the selected glyph | The glyph's rendered content is cleared |
| activity-icon-009 | in-place-state-update | Existing instance, state-update called with activity = waiting, isSummarizing = false | The same instance now renders the waiting glyph; no new instance was created |
| activity-icon-010 | redundant-update-guard | Existing instance at activity = working, isSummarizing = false, then state-update called again with the same values | No re-render, no accessibility re-description, and the running spin animation is left untouched (does not restart) |
| activity-icon-011 | animation-restart-on-change | Existing instance visible on screen at activity = idle, isSummarizing = false (hidden), then state-update called with activity = working, isSummarizing = false | The component becomes visible; a new rotation animation is installed |
| activity-icon-012 | waiting-or-summarizing-pulse | Instance visible on screen, state-update called with activity = waiting, isSummarizing = false | A pulse animation is present; opacity animates 1.0→0.25→1.0, 0.7s each way (1.4s full cycle), repeating |
| activity-icon-012b | waiting-or-summarizing-pulse | Instance visible on screen, state-update called with activity = idle, isSummarizing = true | A pulse animation is present (the pulse fires for the summarizing-and-idle combination the same as any other summarizing case) |
| activity-icon-013 | working-state-spin | Instance visible on screen, state-update called with activity = working, isSummarizing = false | A rotation animation is present, rotating one full turn over 1.1s linear, repeating |
| activity-icon-014 | animation-install-idempotence | Instance already spinning (working), animation start triggered again without an intervening stop | The rotation animation is unchanged (no duplicate animation added) |
| activity-icon-015 | off-window-animation-removal | Instance visible on screen and spinning (working), then removed from the display hierarchy | The rotation animation is removed |
| activity-icon-016 | window-attach-animation-reinstall | Freshly constructed activity = working instance, not yet visible on screen, then inserted into the display hierarchy | The glyph re-renders and a rotation animation becomes present |
| activity-icon-017 | appearance-change-rerender | Instance on screen, the surrounding appearance changes (e.g. system switches light/dark) | The glyph is regenerated with a fill color resolved against the new appearance, not the color that had been resolved against the previous appearance |
| activity-icon-018 | display-scale-rerender | Instance moved to a display with a different pixel density | The rasterized glyph's scale matches the new display's pixel density |
| activity-icon-019 | glyph-bounds-layout | Component resized, a layout pass runs | The glyph's bounds equal the component's bounds; the glyph is centered; no implicit animation plays for the change |
| activity-icon-020 | image-accessibility-role | Any constructed instance | Reports an image accessibility role; is exposed as an accessibility element |
| activity-icon-021 | state-based-label-and-tooltip | Constructed with activity = waiting, isSummarizing = false | Accessibility label and tooltip both read `"Waiting for you"` |
| activity-icon-021b | state-based-label-and-tooltip | Constructed with activity = working, isSummarizing = true | Accessibility label and tooltip both read `"Summarizing"` (summarizing overrides activity) |
| activity-icon-022 | state-based-accessibility-identifier | Constructed with activity = idle, isSummarizing = false | Accessibility identifier reads `"session-panel.activity.idle"` |
| activity-icon-022b | state-based-accessibility-identifier | Constructed with activity = idle, isSummarizing = true | Accessibility identifier reads `"session-panel.activity.summarizing"` |
| activity-icon-023 | programmatic-construction-only | Construction attempted through the serialized-archive path (e.g. a visual-editor-generated layout file) | Process traps with a fatal error |

