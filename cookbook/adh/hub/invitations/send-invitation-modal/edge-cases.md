
- Recipients are seeded once at mount and are never mutated by this modal (the
  recipient list renders read-only); re-seeding for a new selection only happens
  if the caller forces a fresh mount.
- Pre-seeded recipients alone do not make the form "populated" — only note text
  does, so an unmodified, freshly opened modal closes immediately on
  Cancel/Esc/backdrop even though its sections show recipients.
- A single whitespace character in either note counts as populated and triggers
  the discard confirm.
- The Send payload always includes one entry per rendered section, each carrying
  that section's untrimmed note, sent as an empty string when the note is empty.
- Send is disabled only when neither the email list nor the phone list was
  seeded, so no section renders.
- While busy, Cancel/Esc/backdrop are blocked outright — no discard confirm is
  shown even for a populated form.
- State (including notes and the discard confirm) resets on close, so reopening
  via a fresh mount re-seeds from the current inputs.

