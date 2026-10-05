
```
┌ Disclosure — closed (neutral) ─────────────────────────────────────┐
│ ▸  ⚠ Danger Zone                                                    │  ⚠ = gold glyph
└─────────────────────────────────────────────────────────────────────┘

┌ Disclosure — open (red border + tint) ─────────────────────────────┐
│ ▾  ⚠ Danger Zone            ← title text turns red when open         │
│                                                                     │
│  Permanently delete this {noun} and all of its data. Cannot be undone.
│  [ 🗑 Delete {entityNoun} ]      ← destructive-ghost                     │
└─────────────────────────────────────────────────────────────────────┘

Dialog · phase "warn"                    Dialog · phase "confirm"
┌───────────────────────────┐            ┌────────────────────────────────┐
│ Delete {entityNoun}?      │            │ Permanently delete this {entityNoun}│
│ …deletes all data,        │            │ Enter "{confirmValue}" below.  │
│ including {childEntities}.│    Yes →   │ [ type the exact identifier…  ] │
│ Do you wish to proceed?   │            │ (inline error, if any)         │
│        [Cancel] [Yes]     │            │   [Cancel] [Permanently Delete]│
└───────────────────────────┘            └────────────────────────────────┘
                                          Permanently Delete: disabled until
                                          typed === confirmValue (exact); shows
                                          "Deleting…" while busy.
```

The two blocks above are the **default** copy (no `actionVerb`, or `reversible: false`).
Passing `actionVerb={{ imperative: "Archive", gerund: "Archiving", reversible: true }}`
keeps the same red palette and the same two-phase ceremony — only the trigger glyph and
every permanence-asserting phrase change:

```
┌ Disclosure — open (red border + tint) ──────────────────────────────┐
│ ▾  ⚠ Danger Zone            ← still turns red when open               │
│                                                                     │
│  Archive this {noun}. This can be undone later.
│  [ 📦 Archive {entityNoun} ]  ← destructive-ghost; Archive glyph, not 🗑│
└─────────────────────────────────────────────────────────────────────┘

Dialog · phase "warn"                    Dialog · phase "confirm"
┌───────────────────────────┐            ┌────────────────────────────────┐
│ Archive {entityNoun}?     │            │ Archive this {entityNoun}      │
│ …affects {childEntities}. │    Yes →   │ Enter "{confirmValue}" below.  │
│ Do you wish to proceed?   │            │ [ type the exact identifier…  ] │
│        [Cancel] [Yes]     │            │   [Cancel] [Archive {entityNoun}]│
└───────────────────────────┘            └────────────────────────────────┘
                                          Archive {entityNoun}: disabled until
                                          typed === confirmValue (exact); shows
                                          "Archiving…" while busy. No "Permanently" /
                                          "cannot be undone" / "deletion" anywhere,
                                          including the collapsed-section blurb above.
```

- Section root: carries the accessible label "Danger Zone".
- Disclosure: neutral when closed; a red border/tint and a red title when open; the
  warning glyph is gold throughout.
- Dialog description highlights `confirmValue` in a monospace font using the default
  text theme role; the input placeholder is `confirmValue`; inline error text uses
  the red theme role.

