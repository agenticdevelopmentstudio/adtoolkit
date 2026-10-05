
```
┌ Form (vertical layout, gapped rows) ─────────────────────────┐
│ Field  "name *"        [ text input                     ]  │
│ Field  "tier"          [ Select: Select… / free / pro   ]  │
│ ☑  "active"            (boolean rides inline w/ caption)   │
│ Field  "config"  JSON  [ textarea (rows=3)              ]  │
│ Error text (inline, on validation / submit failure)         │
│                                     [ Cancel ]  [ Save ]   │
└────────────────────────────────────────────────────────────┘
```

- Root form container, laid out as a vertical column with a gap between
  rows; one row per writable column.
- Non-boolean: wrapped in a Field (stacked label above the control);
  required labels get ` *`, object/array/unknown get a `JSON` hint.
  Boolean: a horizontally laid-out label pairing the checkbox with a
  caption styled in the shared uppercase-mono caption style.
- Footer: right-aligned, laid out horizontally with a gap — a ghost-styled
  Cancel control and a primary Save control, both small-sized, disabled
  while saving; Save reads "Saving…" while pending.
- Error text renders between the fields and the footer.
- No raw hex colors; no style overrides — color/typography come from the
  toolkit's shared design tokens plus shared classes.

