
- **React/Web**: The component (`AdminNotesModal`) lives at
  `packages/web/packages/adh-ui/src/blocks/admin-notes-modal.tsx` in `@agentic-toolkit/adh-ui`,
  and composes `Dialog`/`DialogContent`/`DialogHeader`/`DialogTitle`/`DialogFooter` and
  `Textarea` from `@agenticdevelopertoolkit/ui/components/dialog` and
  `@agenticdevelopertoolkit/ui/components/textarea`, `Button` from
  `@agenticdevelopertoolkit/ui/components/button`, `ListWithDetailsPane` and
  `DataTableColumn` from `@agenticdevelopertoolkit/ui/blocks/list-with-details-pane`
  and `@agenticdevelopertoolkit/ui/components/data-table`, and the `AdminNote` type
  from `../lib/invitations-types`. Two independent `Dialog` roots are controlled by
  the `open` and `editorOpen` state values respectively; the staged working list is
  held in a `working` state value. The "New note" control is supplied to
  `ListWithDetailsPane` via its `actions` prop (`{ id: "new", label: "New note", onClick:
  openNewNote }`). `addedDate`/`modifiedDate` are produced by
  `new Date().toISOString().slice(0, 10)`; a new note's `id` is generated as
  `note-${Date.now()}`. Fetching and the actual persistence mutation are handled by the
  caller (e.g. via React Query), never inside this component. Styling comes from the
  shared `Dialog`/`Button`/`Textarea` Tailwind classes and `apt-*` theme tokens:
  `rounded-xl`, `p-5`, `text-base font-semibold`, `bg-apt-surface`, `text-apt-gold`/
  `text-apt-text`, `border-apt-border`, `shadow-xl`, `max-w-md`/`max-w-3xl`, `h-[420px]`,
  `max-w-lg`, `min-h-32`.
- **SwiftUI**: Model the outer surface as a `.sheet(isPresented:)` and the note editor as a
  second, `.sheet(item:)`-keyed sheet (an enum for closed/new/editing an id) so both can be
  independently presented. Use a `NavigationSplitView` or a `List(selection:)` plus a detail
  `VStack` for the list/detail pane, and a `TextEditor` with `.accessibilityLabel("Note
  content")` for the note editor. Stage a `@State` working array reset in
  `.onChange(of: isPresented)`, mirroring the source's seed/re-seed effect; `Equatable`
  conformance on the note model gives the dirty check for free.
- **Compose**: Use an `AlertDialog`/`Dialog` composable for the outer surface and a second,
  independently controlled `Dialog` for the note editor. Use a two-pane `Row` (a `LazyColumn`
  list + inline detail `Column`) or a Material 3 adaptive list-detail scaffold in place of
  the list-with-details pane, and an `OutlinedTextField(singleLine = false)` for the note
  editor. Hoist the working list as `remember { mutableStateOf(notes) }`, re-seeding it from
  a `LaunchedEffect(open, notes)` that reproduces the same "only when unedited" guard as the
  source.
- **AppKit/UIKit**: Present the outer surface as a sheet (`NSHostingController`/
  `UIHostingController`, or a native `NSPanel`) and the note editor as a second,
  independently presented sheet. Use an `NSTableView`/`UITableView` for the note list with a
  detail split, and an `NSTextView`/`UITextView` for the note editor, calling
  `setAccessibilityLabel("Note content")` (AppKit) or setting `accessibilityLabel` (UIKit) to
  match the source's accessible label.
- **WinUI 3**: Use a single `ContentDialog` whose content swaps, via a `Visibility` binding
  equivalent to `editingId !== null`, between the two-pane list/detail view (a `ListView`
  bound to the working collection plus a details `Grid`, laid out side by side or switched
  with an `AdaptiveTrigger`/`VisualState` at narrow widths) and the note editor pane (a
  `TextBox AcceptsReturn="True" TextWrapping="Wrap" AutomationProperties.Name="Note content"`).
  Avoid nesting a second `ContentDialog` for the editor — WinUI does not stack them cleanly —
  and instead swap content within the one dialog, keeping a separate "new vs. edit" title
  binding (`"New note"` / `"Edit note"`) on the `ContentDialog`'s `Title`. Bind the primary
  button's `IsEnabled` to a `Dirty && !Busy` view-model property for the list view and to
  `Draft.Trim().Length > 0` for the editor view, mirroring the source's
  `disabled={busy || !dirty}` and `disabled={draft.trim() === ""}`. Rely on `ContentDialog`'s
  default `CloseButtonCommand`/Escape handling for the no-confirmation discard path while in
  list-view content, matching the source's unconfirmed Cancel/Escape/close. Because both
  views share the one `ContentDialog`, that default Escape/`CloseButtonCommand` handling
  would dismiss the whole dialog when it fires in editor-view content — discarding the staged
  working list, not just the draft, which breaks **discards-draft-on-editor-cancel**.
  Override Escape/`CloseButtonCommand` while in editor-view content to return to list-view
  content (mirroring `cancelEditor`) instead of closing the `ContentDialog`; see the matching
  Design Decision below.

