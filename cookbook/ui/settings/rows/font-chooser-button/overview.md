
The font chooser button is itself the font sample: it draws a
caller-supplied font's name in that font, at one fixed legible size, and
opens the platform's font-selection UI when clicked. It receives the font
the user picks there and forwards it through a change callback. It
records nothing durable of its own — the caller (the row or view model
that owns the setting) decides what the picked font means, persists it if
appropriate, and hands the button back whatever it actually recorded,
including a clamped size or an edit a locked theme refused outright.

