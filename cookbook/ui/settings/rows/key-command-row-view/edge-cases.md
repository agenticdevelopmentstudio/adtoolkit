
- Null/empty input: The command descriptor and registry are non-optional,
  typed constructor parameters; the type system rules out a missing value
  for either (see **requires-a-command-and-a-registry-to-construct**). The
  command's title as an empty string produces a title label reading `":"`
  with no crash.
- Boundary values: Not this file's own boundary — this component imposes
  no minimum-modifier or chord-shape check itself; it defers entirely to
  the registry's own availability check, which is the component that
  requires at least one modifier key before a chord is considered
  available.
- Concurrent access: Not applicable — this component and the registry are
  both confined to the UI thread, so all construction, mutation, and
  notification handling is serialized to that thread (see
  **confines-to-ui-thread**).
- Error states: Not applicable in the throw/catch sense — no throwing
  operation is called anywhere in source. The one failure domain the
  component has — a chord that cannot be assigned — is modeled as data (an
  unavailability reason) and surfaced through the refusal/status-label
  requirements above (see **refuses-commit-of-an-unavailable-chord**,
  **refuses-toggle-on-when-the-current-chord-is-taken**), a MUST-level
  behavior rather than an omission.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own; it only reads from and writes to the in-process
  registry.
- Click in, then click out with nothing captured: if the user focuses the
  capture field and it resigns focus before any chord is captured, the
  recording-stopped callback fires with no chord pending, so the row
  leaves the mid-edit state and the confirm/cancel pair and readout row
  hide again — per
  **ends-editing-when-recording-stops-with-nothing-pending**, and called
  out in source's own comment: "Clicked in and straight back out without
  pressing anything: there is nothing to confirm, so the pair should not
  linger."
- Re-recording a shipped-off, never-touched command versus one the user
  explicitly turned off: both have the same disabled binding state at the
  moment of recording, but the committed result differs — a shipped-off
  command with no authored binding turns on (**enables-command-on-first-or-
  unbound-commit**), while a command the user themselves switched off stays
  off (**preserves-enabled-state-on-rebind**) — because the row
  distinguishes "never authored" from "authored and off" via the
  registry's own authored-binding check, not merely by reading the current
  enabled flag. This is a MUST-level, source-traceable distinction; see
  Design Decisions.
- A binding change caused by a different row while this row is mid-edit:
  the registry's bindings-changed notification fires for every binding
  write, including ones made by sibling rows sharing the same registry.
  The refresh path only reassigns the capture field's displayed
  shortcut/placeholder and the toggle's state/enabled flag from the current
  binding — it never touches the pending shortcut or the mid-edit state —
  so an edit already in progress on this row survives a binding change
  made elsewhere (see **preserves-pending-edit-on-external-change**).
- A refusal shown after a toggle refusal, with no active recording: the
  refusal path sets the refusal message without entering the mid-edit
  state; the readout row's visibility still reacts to a pending refusal
  independently of the mid-edit state. The refusal message clears along
  either of two paths: the next edit beginning (entering the mid-edit
  state clears any pending refusal), or an accepted toggle change, which
  clears the refusal directly before writing the binding (see
  **clears-refusal-on-an-accepted-toggle-change**). Absent either, the
  refusal persists on screen — traced directly to the component's own doc
  comment: "shown in the readout until the next edit."

