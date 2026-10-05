
Vectors that reference a system-provided color assume tests run under a
fixed system appearance mode, since such colors can resolve to different
underlying values under light vs. dark appearance.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| badge-001 | renders-rounded-pill | Construct with any text and color | The badge's background has a corner radius of 5 |
| badge-002 | displays-caller-text | Construct with text "dev" and a green color | The label's text is exactly "dev" |
| badge-003 | defaults-to-filled-style | Construct with text "dev" and a green color (no style), under a fixed system appearance mode | Background is green; border width is 0 |
| badge-004 | paints-filled-background | Construct with text "dev", a green color, style filled, under a fixed system appearance mode | Background equals green; border width equals 0 |
| badge-005 | computes-contrasting-text-color | `color` = light gray, RGB (230, 230, 230) i.e. (0.902, 0.902, 0.902) in sRGB 0–1 — luminance ≈ 0.902 | Label text color is black |
| badge-005b | computes-contrasting-text-color | `color` = dark navy, RGB (0, 0, 128) i.e. (0, 0, 0.502) in sRGB 0–1 — luminance ≈ 0.057 | Label text color is white |
| badge-005c | computes-contrasting-text-color | `color` = mid-gray, RGB (153, 153, 153) i.e. (0.6, 0.6, 0.6) in sRGB 0–1 — luminance exactly 0.6 (boundary: the comparison is `>` 0.6, not `>=`) | Label text color is white |
| badge-006 | falls-back-to-white-on-unconvertible-color | `color` for which conversion to the sRGB color space fails (e.g. a pattern-image color), style filled | Label text color is white |
| badge-007 | paints-outlined-appearance | Construct with text "3", a red color, style outlined, under a fixed system appearance mode | Background is clear/transparent; border width equals 1; border color equals red; label text color equals red |
| badge-008 | supports-in-place-restyle | Existing badge, then restyle with text "stopped", a gray color, style outlined, under a fixed system appearance mode | Label reads "stopped"; background/border/text reflect outlined with gray |
| badge-009 | resets-style-to-filled-by-default-on-update | Badge currently outlined, then restyle with text "3", a blue color (no style) | Badge renders filled (solid blue background, border width 0), not outlined |
| badge-010 | applies-fixed-content-padding | Any badge | Label's leading/trailing insets resolve to 6pt; top/bottom resolve to 2pt |
| badge-011 | centers-label-text | Any badge | The label's text is center-aligned |
| badge-012 | tracks-theme-caption-font | Theme change while a badge is on screen | Label's font updates to the new theme's caption font |
| badge-013 | sizes-to-fit-content | Badge placed with no explicit width constraint | Badge's fitting width equals the label's intrinsic width plus 12pt (6pt × 2) horizontal padding; badge does not stretch to fill a wider container |
| badge-014 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |
| badge-015 | rejects-storyboard-instantiation | Attempt to construct the control from a serialized or archived representation | Construction is refused as a programmer error and terminates; no instance is produced. Verified by inspection only, since the refusal cannot be caught. |
| badge-016 | minimum-contrast-ratio | Outlined badge whose `color` is nearly the same as the host background | Text and border are exactly `color`; no contrast adjustment is applied. |

`confines-to-ui-thread` is vector badge-014 and `rejects-storyboard-instantiation` is vector badge-015; both are verified by inspection only (see Platform Notes).

`prefers-semantic-palette-colors` has no test vector: it is a SHOULD
constraining what colors a caller chooses to pass in, not an observable
behavior of the component itself, so no component-level test can verify it
(see Design Decisions).

