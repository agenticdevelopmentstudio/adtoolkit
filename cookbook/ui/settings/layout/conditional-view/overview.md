
The conditional view is a settings container that shows or hides a single
caller-supplied child view based on the live value of an observed setting,
re-evaluating a caller-supplied visibility predicate every time the
setting's value changes. It exists to show a settings group only when
another setting takes a particular value — for example, showing a
"Custom Command" group only when a click-action setting equals
`custom_command`. It self-reports visibility changes so a hosting group
view can collapse the padding and hairline around a card row whose content
has hidden itself, rather than leaving an empty band behind.

