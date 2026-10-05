
| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; value label shows the current integer value as plain digits; the stepper's value matches. |
| At minimum value | The stepper's value equals its minimum; because wraparound is disabled, further decrements are absorbed by the stepper's own bounds enforcement rather than wrapping to the maximum. This is the stepper's native behavior given the minimum/wraparound configuration the component sets (see disables-stepper-wraparound), not custom drawing in this file. |
| At maximum value | Symmetric to the minimum case: the stepper's value equals its maximum, further increments are absorbed rather than wrapping to the minimum. |
| Pressed | Not applicable: the component renders no button of its own; the stepper's own arrow-press highlight while clicked is the platform's default rendering, not custom to this file. |
| Disabled | Not implemented in the component; the enabled state is never read or set on the label, value label, or stepper in source. A caller may set the stepper's enabled state directly through the public stepper property, at which point the platform's native disabled dimming applies. |
| Focused | Not styled by the component; any focus ring when the stepper is tabbed to is the platform's own native focus appearance. |
| Loading | Not applicable: the component has no asynchronous operation and no loading indicator in source. |

