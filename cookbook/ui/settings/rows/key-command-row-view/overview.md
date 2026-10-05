
The key command row is the settings row for one bindable command in the Key
Commands panel:
`[title] … [click-to-record field] [confirm | cancel] [on/off]`, with a status
readout appearing underneath while an edit is pending or a refusal is being
shown. It composes four child controls — a title label, a capture field that
records a chord, a confirm/cancel pair, and a toggle switch — around a single
command descriptor and the shared key-command registry that owns every
command's binding and answers whether a chord is free.

The row, not the capture field, owns the pending-edit state. Per the source's
own doc comment, a captured chord is pending until the user commits it, and
focus can leave the field in the middle of that (the user clicks the
confirm/cancel pair, which is a separate view), so the state that decides
whether the confirm/cancel pair and the status readout are on screen cannot
live in the view that loses focus — it lives in the row.

