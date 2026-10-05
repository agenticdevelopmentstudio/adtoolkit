
Applicable, and unmet: every user-facing string in this file — `"Search"`,
`"Help"`, `"Show Help"` / `"Hide Help"`, `"Arrange Panes"`, `"Project
Settings"`, `"Panes"`/`"Minimizing"`/`"Zoom"`/etc. help topic bodies, and the
default tab title `"Tab \(n)"` — is a hardcoded English literal. No
localization key lookup exists in source. This is recorded as accepted debt
in Design Decisions above, and is reflected in Compliance below
(`string-externalization`, `no-hardcoded-strings`).

