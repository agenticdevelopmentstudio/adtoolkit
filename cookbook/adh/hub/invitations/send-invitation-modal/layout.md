
```
┌ Send invitation ───────────────────────────────────────┐
│  SMS                                                    │  ← only if phones seed non-empty
│  Recipients  ( +1 555 0100 )                            │  ← read-only, seeded
│  Note (opt.) [                              ]           │
│                                                         │
│  EMAIL                                                  │  ← only if emails seed non-empty
│  Recipients  ( ada@x.io )( grace@x.io )                 │  ← read-only, seeded
│  Note (opt.) [                              ]           │
│                                                         │
│                                  [ Cancel ]  [ Send ]   │
└─────────────────────────────────────────────────────────┘
```

- The dialog is sized to a moderate maximum width; sections are grouped as labeled
  field blocks. Footer is right-justified with Cancel and Send; Send uses the
  button's default visual style with no color override — the gold accent styles
  the dialog's title, not the Send button.
- No raw hex; no `!important`.

