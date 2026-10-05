
| State | Appearance change |
|-------|------------------|
| Idle, not summarizing (activity = idle, isSummarizing = false) | Hidden; no glyph is drawn and no animation runs. |
| Working, not summarizing (activity = working, isSummarizing = false) | Visible; the circular double-arrow glyph tinted with the theme's accent color role; spins one full clockwise turn every 1.1s, indefinitely. |
| Waiting, not summarizing (activity = waiting, isSummarizing = false) | Visible; the circled-exclamation-mark glyph tinted with the theme's warning color role; opacity pulses 1.0→0.25 and back, 0.7s each way (1.4s full cycle), indefinitely. |
| Summarizing (isSummarizing = true, any activity) | Visible; the sparkle glyph tinted with the theme's accent color role; opacity pulses 1.0→0.25 and back, 0.7s each way (1.4s full cycle), indefinitely — the same pulse as Waiting, regardless of the underlying activity. |
| Pressed | Not applicable: the component defines no interaction handling of any kind — this is a purely visual, non-interactive display element with no pressed state to represent. |
| Disabled | Not applicable: the component defines no enabled/disabled property or dimmed-appearance branch. |
| Focused | Not applicable: the component never becomes focused; it uses the platform's default (non-focusable) behavior unmodified. |
| Loading | Not applicable: the component performs no asynchronous operation of its own and defines no loading flag; the "Working"/"Waiting" rows above are externally supplied state this component renders, not a loading operation it performs. |

