
The Text Area Edit View is a settings row: a multi-line editor for a setting
whose value is "a body of text rather than a field's worth" — an LLM prompt, a
template, or a script snippet. It pairs a title label with a scrolling text
editor in a vertical stack, and unlike the single-line Text Edit View (which
commits on Return), it writes the value back only when editing *ends* — the
editor loses focus, its window closes, the host application terminates, or the
component is detached from its window — because Return inserts a newline
rather than submitting. The component is driven by a view model exactly as the
Text Edit View and the Secure Text Edit View are, reusing only the Text Edit
View's label-construction helper rather than composing the label
independently (see Design Decisions).

