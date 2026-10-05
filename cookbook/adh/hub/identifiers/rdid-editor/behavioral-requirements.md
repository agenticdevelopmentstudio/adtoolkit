
- **renders-associated-label**: The editor MUST render its label
  associated with the input, so assistive technology and a pointer click
  on the label both target the input.
- **generates-stable-input-id**: The editor MUST use a caller-supplied
  input identifier when provided, and otherwise MUST generate a stable
  one itself, so the label association always resolves to a real
  element.
- **renders-static-prefix**: WHEN `prefix` is a non-empty string, the
  editor MUST render it as static, non-interactive text immediately
  before the input, and MUST NOT include it in the input's editable
  value.
- **renders-single-input-without-prefix**: WHEN `prefix` is the empty
  string, the editor MUST render one full-width input with no prefix
  element, so the entire value is editable.
- **displays-controlled-value**: The editor MUST render the input's
  current value from the value it is given (a controlled component; it
  holds no value state of its own).
- **lowercases-input-on-change**: On every input change, the editor MUST
  report the new value converted to lowercase.
- **forwards-placeholder**: WHEN a placeholder is provided, the editor
  MUST set it as the input's native placeholder text.
- **shows-hint-below-input**: WHEN a hint is provided and no error is,
  the editor MUST render the hint in the footnote slot below the input.
- **shows-error-in-place-of-hint**: WHEN an error is provided, the editor
  MUST render the error in the footnote slot below the input instead of
  the hint.
- **marks-input-invalid-on-error**: WHEN an error is provided, the editor
  MUST mark the input as invalid to assistive technology.
- **omits-invalid-attribute-without-error**: WHEN no error is provided,
  the editor MUST NOT mark the input as invalid at all (not even an
  explicit "not invalid" marker).
- **disables-input-when-disabled**: WHEN disabled, the editor MUST
  render the input in a disabled state that rejects further edits.
- **supports-native-keyboard-input**: The editor MUST accept text entry
  and full keyboard focus navigation through the platform's native text
  input; the source attaches no custom key handlers that would intercept
  or block native keyboard behavior.

