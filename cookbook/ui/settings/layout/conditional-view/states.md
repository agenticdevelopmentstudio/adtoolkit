
| State | Appearance change |
|-------|------------------|
| Default | The child view is added as the only content and pinned to the container's edges; the shown/hidden state is set from the current visibility evaluation before the view is ever displayed, so there is no unevaluated frame. |
| Visible | Shown; set whenever the visibility predicate returns `true` for the setting's current value. The visibility-change callback fires once on a transition into this state from Hidden — never during the initial evaluation at construction, because no caller has had the chance to assign the callback at that point. |
| Hidden | Hidden; set whenever the visibility predicate returns `false` for the setting's current value. The visibility-change callback fires once on a transition into this state from Visible, for the same reason the Visible row's initial-evaluation exception applies. |
| Pressed | Not applicable: the component is a plain container — it defines no target/action and receives no press interaction of its own. |
| Disabled | Not implemented; an enabled/disabled concept is never read or set. |
| Focused | Not styled by the container; any focus ring belongs to the child view, not to this container. |
| Loading | Not applicable: the component performs no asynchronous operation and shows no loading indicator. |

