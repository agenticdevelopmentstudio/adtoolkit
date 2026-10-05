
| State | Appearance change |
|-------|------------------|
| Default | The hint label and dismiss button are added inside the pinned stack; the shown/hidden state is set from the observed setting's value before the view is ever displayed, so there is no unevaluated frame. |
| Visible (not yet dismissed) | Shown. |
| Hidden (dismissed) | Hidden, set once the observed setting's value becomes `true` and is delivered through the observer; the visibility-change callback fires once on the transition. |
| Pressed | Not applicable to the composite view: the dismiss button's own pressed-state highlight is the platform's default system behavior, not custom-drawn by this component. |
| Disabled | Not implemented; an enabled/disabled concept is never read or set. |
| Focused | Not styled by the component; any focus ring belongs to the dismiss button's own default focus appearance — no custom focus handling applies. |
| Loading | Not applicable: the component performs no asynchronous operation and shows no loading indicator. |

