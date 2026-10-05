
```
LOGGED OUT (marketing)               LOGGED IN (/home + workspace)
──────────────────────               ─────────────────────────────
[LogIn]     Login                    [Home]     Home
[UserPlus]  Sign up                    [Boxes]  Workspaces        ▸ flyout
                                     [History]  Recents           ▸ flyout
── section divider ──                ── section divider ──
[Hub icon]  Hub                      [Hub icon]  Hub
  [Bot]      BitBag                    [Bot]       BitBag
  [Users]    Community                 [Users]     Community
  [UserCircle] Persona Registry        [UserCircle] Persona Registry
  [Wrench]   Toolkit                   [Wrench]    Toolkit
  [ChefHat]  Cookbook                  [ChefHat]   Cookbook
  [UsersRound] Dev Team                [UsersRound] Dev Team
  [Sparkles] MyAgenticTeams            [Sparkles]  MyAgenticTeams
  [ScrollText] Narratives              [ScrollText] Narratives
  [CircleHelp] Help                    [CircleHelp] Help
                                       [Newspaper]  News
                                       [Network]    Ecosystems
                                       [UserCircle] Personas
                                       [Building]   Organizations
                                       [FlaskConical] Research
```

- Indentation (2 spaces) = **inline sub-item**, always visible.
- `▸` = **flyout submenu** (the existing `topic` popover disclosure).
- Row visual language is unchanged from `NavigationPopover`: label
  `adh-nav-popover__link-name`, optional description below/beside; the icon sits in
  a fixed-width leading slot, `apt-text-muted`, sized to the label line.
- Icons are lucide-react; the exact glyph per row comes from the single source of
  truth (see Integration Requirements). Icons shown above are the proposed set;
  reused-where-existing, chosen-where-absent.
- Section divider between the top (auth) section and the Hub section reuses the
  existing section-break treatment (`MenuGroup.section` boundary).

