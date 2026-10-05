
Not applicable: this component builds no string intended for an end user
to read. The only text this file produces beyond SQL statements is the
diagnostic message carried inside a thrown error's payload (SQLite's or
the OS's own error string) — a raw error string with no localization key —
but nothing in this file presents that string to a user; it exists to be
caught and handled programmatically by a caller.

