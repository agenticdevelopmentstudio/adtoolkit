
```
┌──────────────────────────────────────────────────────────────┐
│ 12 rows                                              [ New ]   │
│ (error line, when error != null)                              │
├──────────────────────────────────────────────────────────────┤
│  id        name         status      …            (actions)    │
│ ─────────────────────────────────────────────────────────────│
│  ab12…      Ada          active            [ Edit ] [ Delete ]│
│  cd34…      Grace        —                 [ Edit ] [ Delete ]│
└──────────────────────────────────────────────────────────────┘
     loading → centered Spinner ·  empty → "No rows yet."
```

- Outer: `flex min-w-0 flex-col gap-3`. Header row: `flex items-center
  justify-between gap-2` with a `font-mono text-[0.7rem] text-apt-text-dim` count
  on the left and a `size="sm"` primary `Button` ("New") on the right.
- Table: wrapped in `overflow-x-auto rounded-lg border border-apt-border`;
  `w-full text-left text-sm`. Header cells use the shared `fieldCaptionClass` +
  `px-3 py-2 font-medium`; body cells `px-3 py-2 text-apt-text`; row separators
  `border-b border-apt-border/50`.
- Actions cell: right-aligned, `whitespace-nowrap`, two `variant="ghost"
  size="sm"` buttons (Edit, Delete).
- No raw hex; no `!important` (all color via `apt-*` tokens).

