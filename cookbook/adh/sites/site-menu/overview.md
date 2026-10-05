
`SiteMenu` is the platform's primary navigation menu — the popover disclosed from
the header wordmark. It renders a vertical list of rows, each `[icon] [label]
[description]`, organized into sections. It has one shared core layout used by
**both** the marketing (logged-out) and workspace (logged-in `/home`) surfaces;
only the **top section** differs by auth state.

It is chrome. The menu itself — `SiteMenu` and the `menu-icons` map — is ADH
vocabulary, and the registry-free machinery it composes (`NavigationPopover`, the
recents store) is generic; both halves now live in `@agentic-toolkit/adh/header`,
so the tier boundary this recipe once straddled is gone. It is built by composing that
`NavigationPopover` (surface, search, keyboard nav, flyout submenus) with a
declarative config (`MenuGroup[]`). This recipe defines the enhanced menu:
per-row **icons** from a single source of truth, a new **inline sub-item** row
kind, a **Hub** section that gathers the ecosystem's sites and tools, and an
auth-conditional **top section** that adds **Login/Sign up** when logged out and
**Home / Workspaces / Recents** when logged in. Recents records the last 10 places
the user actually landed on and deep-links back to each.

