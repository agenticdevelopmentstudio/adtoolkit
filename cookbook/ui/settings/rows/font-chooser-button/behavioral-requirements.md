
- **system-placeholder**: On construction, the component MUST initialize
  itself with no font selected: `title` set to `"System"`, `selectedFont`
  set to `nil`, and `font` set to the system font at the sample size.
- **rounded-momentary-style**: On construction, the component MUST render
  with rounded corners and behave as a momentary push control — depressing
  while pressed and returning to normal on release, taking no other action
  itself.
- **title-alignment**: On construction, the component MUST left-align its
  title text.
- **tail-truncation**: On construction, the component MUST truncate
  overflowing title text at the tail (end), with the omission shown there.
- **yields-width-under-compression**: On construction, the component MUST
  be configured to readily give up width when horizontal space is
  constrained, rather than resisting the squeeze.
- **expands-to-fill-remaining-width**: On construction, the component MUST
  be configured to expand into available horizontal space rather than
  hugging its title's intrinsic width tightly.
- **fixed-width-constraint**: WHEN constructed with an explicit, non-nil
  fixed width, the component MUST activate a width constraint equal to
  that width.
- **no-width-constraint**: WHEN constructed with an explicit `nil` width,
  or via the plain default constructor, the component MUST NOT add any
  width constraint of its own.
- **coder-init**: The component MUST reject construction via a
  serialization/decoding-based construction path.
- **sample-size**: WHEN the component is given a non-nil font, it MUST
  render the title using that font converted to the sample size (12pt),
  regardless of the font's own point size.
- **system-font-fallback**: WHEN the component is given a `nil` font, it
  MUST render the title in the system font at the sample size.
- **selected-font-size**: WHEN the component is given a font, it MUST
  record that exact font, at its own unconverted size, as the selected
  font — not the sample-size font drawn on the button.
- **caller-supplied-title**: WHEN the component is given a title, it MUST
  display exactly that title verbatim.
- **font-persistence**: The component MUST NOT write the recorded selected
  font to any store of its own (a default, a theme, a file); it exists
  only in memory for the component's own lifetime, and only until the next
  time it is given a new font and title.
- **opens-font-picker**: WHEN the button is activated, the component MUST
  open the platform's font-selection UI, seeded with the currently
  selected font if one exists (otherwise the system font at the platform's
  default size), and bring that UI to the front.
- **panel-modes**: The component MUST restrict the font-selection UI it
  opens to font family, face, and size choices only, excluding color and
  text-effect options where the platform's font-selection UI offers them.
- **font-change-forwarding**: WHEN the platform reports a font-selection
  change, the component MUST invoke its change callback (if set) with the
  selected font as it stands at that moment (or the system font at the
  platform's default size if no font is selected yet) — not necessarily
  the font the picker was originally opened on, since giving the component
  a new font and title while the picker is still open replaces the
  selected font before the change is reported.
- **nil-sender**: WHEN the platform reports a font-selection change with
  no accompanying context, the component MUST NOT invoke its change
  callback and MUST take no other action.
- **releases-picker-registration-on-removal**: WHEN the component is
  removed from its window and it is still the active recipient of
  font-picker selections, it MUST release that registration.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **selected-font-access**: The component MUST expose the selected font as
  a public, externally-read-only property.
- **change-callback-access**: The component MUST expose the change
  callback as a public, externally-settable property.

