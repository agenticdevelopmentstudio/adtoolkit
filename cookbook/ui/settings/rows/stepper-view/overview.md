
The Stepper View is a settings row: a title label leading, a monospaced
numeric value label, and a trailing stepper control, bound to a bounded
range view model. Per the source's own doc comment, it is for "small
bounded counts (recents, retry limits, etc.) where a slider's resolution
is wrong but a free text field is too unbounded." Unlike its sibling row
types (the checkbox row's switch, the integer field row's text field),
the stepper control draws no visible number of its own — only up/down
arrows — so this component pairs it with a separate value label that it
keeps in sync with the stepper's value on every change.

