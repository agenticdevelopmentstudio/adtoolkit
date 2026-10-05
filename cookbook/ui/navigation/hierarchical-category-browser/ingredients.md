
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| Category Picker | agenticdevelopertoolkit://recipes/category-picker-dialog | The dialog behind BOTH place-picking gear actions — browses the folded forest and returns a place to file the selected category under. | yes | Move: `confirmLabel="Move"`, `allowRoot`, `rootLabel` = "Top level" or "Remove from “<parent>”" (see #integration-requirements/not-call-an-unfiling-a-rooting), `disabledIds` = the moved category + its own descendants. Also file: `confirmLabel="File"`, `initialSelectedId={null}`, NO `allowRoot` (a root is a category with no parents, so there is nothing to add), `disabledIds` = the category + its descendants + every parent it is ALREADY filed under. |

The other three gear dialogs (Rename, Delete, and the one-field Add) are plain
compositions of the shared `Dialog`/`Input`/`DialogActions`/`AlertModal`
primitives with no dedicated recipe of their own — see
[Dialog](agenticdevelopertoolkit://recipes/dialog),
[Dialog Actions](agenticdevelopertoolkit://recipes/dialog-actions) and
[Alert and Dialog](agenticdevelopertoolkit://recipes/alert-and-dialog) for those.
`useCategoryLevels` wires all four; this recipe documents the whole.

