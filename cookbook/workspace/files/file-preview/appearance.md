
- **Corner radius**: Not applicable — the component never sets a corner radius; any rounding is the native preview control's own chrome, not code in this file.
- **Padding**: Not set by this component — it has no content of its own to pad. The space around the preview is entirely up to whatever container hosts it (in the file editor view, a fill-the-available-space constraint applied by the caller, which is out of scope for this recipe).
- **Font**: Not applicable — the component renders no text of its own; any text visible inside the preview (e.g., a text-file rendering, or the preview control's own captions) is the native preview control's content.
- **Background**: Not set by this component — the native preview control draws its own background and content; no color or theme lookup appears anywhere in the source.
- **Foreground/Text**: Not applicable — the component sets no foreground color or text of its own.
- **Border**: None; the component never sets a border on the view or its layer.
- **Shadow**: None; the component never sets a shadow on the view or its layer.
- **Min/Max size**: The view is constructed with a zero-size frame; the component sets no width, height, or aspect constraint of its own, so its rendered size is determined entirely by whatever layout the caller applies.

