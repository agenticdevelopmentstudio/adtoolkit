
This component declares the data and validation shapes for one
`vscode.window.showInputBox` call — a validation severity, a validation
result, and the input-box request itself — and the thread-confined
presenting role that an implementation conforms to in order to show a text
field for that request and report back what the user did. This role is
declared as its own role rather than an addition to the message-presenting
role or the quick-pick-presenting role, for interface-segregation reasons
(see Design Decisions). The picker presenter is named directly in this file
as the production implementation, serving this seam and the
quick-pick-presenting role both. The component itself performs no
networking, persistence, or UI construction — it is a pure data/role
declaration; every side effect belongs to an implementation.

