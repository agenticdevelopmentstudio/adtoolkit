
- **seed-sections-from-props**: On open, the Email section MUST seed its recipient
  list from the given email list and the SMS section MUST seed from the given phone
  list. Seeding happens once, at mount: changes to those seed lists while the modal
  stays mounted do NOT re-seed it — the caller MUST force a fresh mount to re-seed
  for a new selection.
- **hide-empty-sections**: A section MUST NOT be rendered when its seed list is
  empty or absent (an email-only batch shows only the Email section).
- **recipients-are-read-only**: Each rendered section's recipient list MUST render
  read-only. This modal performs no validation or deduplication of the seed lists;
  the recipients shown are exactly the caller-provided seed list, unchanged for the
  life of the mount.
- **provide-note-per-section**: Each rendered section MUST include an optional
  admin note field.
- **assemble-send-payload**: Send MUST assemble a payload containing one entry per
  rendered section (every rendered section has ≥1 recipient by construction, since
  recipients are read-only and always equal to the seed), each with its full
  recipient list and its note text included verbatim — untrimmed, and as an empty
  string when empty — and MUST call the send callback with it.
- **disable-send-when-empty**: Send MUST be disabled when no section is rendered,
  i.e. both the email and phone seed lists are empty or absent.
- **confirm-cancel-when-populated**: Cancel, Esc, or a backdrop click MUST run the
  same populated check: when the form is populated — at least one of the email or
  SMS note is non-empty, including a whitespace-only note; pre-seeded recipients
  alone never count as populated — it MUST open a discard-confirmation alert
  ("Discard this invitation?" / Cancel · Discard, with Discard styled as
  destructive — red and with Enter-to-confirm disabled), closing only on confirm;
  when not populated it MUST close immediately.
- **no-enter-to-send**: Enter MUST NOT trigger Send from anywhere in the modal —
  the Send control has no default/submit binding, and Enter in the note field
  inserts a newline rather than submitting. This is a separate rule from
  confirm-cancel-when-populated's own Enter-to-confirm-discard rule for the Discard
  button.
- **block-dismissal-when-busy**: When the busy state is true, the Send control MUST
  be disabled and MUST show a spinner in place of its label, and the modal MUST
  block all dismissal outright — Cancel, Esc, and backdrop click are ignored with
  no discard confirm shown, even when the form is populated.
- **reset-on-close**: The modal MUST reset its state (recipients, notes, and the
  discard-confirm) on close.
- **label-controls**: Each recipient list and note field MUST be labeled, and the
  dialog MUST provide modal semantics with focus trap and restore.
- **custom-title**: The dialog title MUST render the given title text, defaulting
  to "Send invitation" when it is omitted.

### API

- **Payload delivered to the send callback**: an object with an optional `email`
  entry and an optional `sms` entry, present only for a rendered section; each
  entry carries `recipients` (that section's list of recipient strings) and
  `note` (that section's untrimmed note text, an empty string when empty).
- **Inputs**: `open` (whether the modal is shown); `emails` (optional list of
  strings seeding the Email section; the section is hidden when empty or
  absent); `phones` (optional list of strings seeding the SMS section; the
  section is hidden when empty or absent); `onSend` (called with the assembled
  payload); `onClose` (called to close the modal); `busy` (optional; disables
  Send and blocks dismissal while true); `title` (optional; overrides the
  dialog heading, defaulting to "Send invitation").

