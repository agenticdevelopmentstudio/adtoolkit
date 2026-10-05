
```
┌──────────────────────────────────────────────────────────────────┐
│  [ Selector popup ▾ ]                                              │  ← top-left popup
├───────────────┬──────────────────────────────────────────────────┤
│  TOPIC LIST   │  DETAIL PANEL                                      │
│               │                                                    │
│  {Entity}     │   (content for the selected topic)                │
│  {Topic 2}    │                                                    │
│  {Topic 3}    │                                                    │
│  …            │                                                    │
└───────────────┴──────────────────────────────────────────────────┘
```

- **No action bar.** A full-width `New | divider | Delete` bar is never rendered above the grid; New lives in the selector popup, Delete lives in the entity pane's Danger section.
- In the **All** view the detail panel is replaced by the All index and the topic list is not shown (there is no focused entity).

The All view toolbar (upper-right):

```
┌──────────────────────────────────────────────────────────────────┐
│  All {Entities}                  [ filter… ]   [▦ cards] [☰ list] │  ← toolbar
├──────────────────────────────────────────────────────────────────┤
│   … cards grid  OR  list rows …                                   │
└──────────────────────────────────────────────────────────────────┘
```

The two-step delete (step 2, type-to-confirm):

```
You are about to permanently delete this {Entity}.

Enter "{rdid}" below
┌────────────────────────────────────────────┐
│                                            │   ← text entry
└────────────────────────────────────────────┘
                              [ Cancel ]  [ Permanently Delete ]   ← red, disabled
```

Color only via `apt-*` tokens (`apt-red` destructive, `apt-border`, `apt-text-muted`, …). No raw hex / arbitrary colors / `!important`.

