
| State | Appearance change |
|-------|------------------|
| With file | Strip shows one button per path segment, chevron-separated, root to leaf |
| No file (open file unset) | Strip is empty; no crumbs or chevrons are rendered |
| Single crumb (file outside the project root, or equal to it) | Strip shows exactly one button, the file's last path component; no chevrons |
| Popover open | One popover is visible, anchored to the clicked crumb, listing that crumb's directory; any previously open popover has been closed first |
| Crumb pressed | Not applicable: crumb buttons are stock platform buttons using an inline style; pressed appearance is the platform's own button-press rendering, not code in this component |
| Crumb focused | Not applicable: keyboard focus is the platform's own default button focus-ring rendering; the source draws no custom focus indicator |
| Crumb disabled | Not applicable: the source never disables a crumb button; every crumb is enabled once created |
| Loading | Not applicable: rebuilding the strip is synchronous; the component has no asynchronous or loading state |

