
This is a settings-pane section that moves an owned object to a different
destination workspace, or a nested Product beneath one. It renders as a
disclosure labeled "Transfer Ownership" that is collapsed by default;
opening it reveals a short explanation of what a transfer does and a
dropdown of candidate destinations (`targets`), where a destination with
`children` renders as a nested submenu (a workspace's own Products).
Picking a non-current destination runs a caller-supplied server preflight
(`onPreview`) and opens a confirmation dialog that names every principal
who will lose access before the transfer runs. The final Transfer action
stays disabled until the user retypes the object's own `entityLabel`
(edge whitespace forgiven, everything else exact). This section is a
sibling of the delete-entity section, whose confirm vocabulary and
type-to-confirm gate it follows.

