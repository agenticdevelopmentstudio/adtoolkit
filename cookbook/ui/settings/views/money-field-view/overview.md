
The money field is a labelled text row for an amount stored as integer cents. The text is typed and shown through a formatter the caller supplies, asked for afresh on every read so a currency that changes while the pane is open re-renders in the new format. Text that does not parse, or parses outside the allowed range, is refused: nothing is written and the row shows the stored amount again. When blanks are allowed, an empty field writes nothing-as-an-amount (use the fallback) and a placeholder shows what that fallback is.

