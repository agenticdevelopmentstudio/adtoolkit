
| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; the editor's text equals the view model's value, rendered in the theme's body/code font and colors described in Appearance. |
| Focused | Not styled by the component — no focus-ring customization is applied; the platform's own default focus indicator applies when the editor gains focus. |
| Committed | After a commit runs (per end-editing-commit, window-detachment-commit, or teardown-notification-observers) and the editor's text differs from the committed value, the new value is written through (see commit-echo-guard). |
| External value adopted | When the view model's change notification fires with a value the component did not itself just write, the editor's text is replaced with the new value (see external-value-adoption), and the caret jumps to its end if the editor currently has focus (see caret-position-on-external-change). |
| Disabled | Not implemented: the editor's editable/selectable state is never set (both default to enabled, so the field is always editable). A caller may disable it directly through the component's exposed editor (see constituent-view-exposure), though doing so produces no automatic visual dimming the way disabling a standard control would. |
| Pressed | Not applicable: a text editor has no discrete pressed state distinct from gaining focus and placing the caret; no such state is drawn. |
| Loading | Not applicable: the component performs no asynchronous operation and shows no loading indicator. |

