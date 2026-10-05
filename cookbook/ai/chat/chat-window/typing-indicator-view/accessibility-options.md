
| Option | Behavior |
|--------|----------|
| Reduce Motion | The pulsing opacity animation runs unconditionally once the animation is started; the component does not read the system's reduce-motion setting or observe changes to it, so a user with that preference enabled sees the same continuous looping pulse as everyone else. |
| Increase Contrast | The container fill (0.08 alpha) and the dimmed dot state (0.3 alpha) are both deliberately low-contrast by design, and the component does not respond to the system's increase-contrast setting: nothing in the component reads that setting to raise either value; see **low-alpha-contrast** and its Design Decision. |
| Differentiate Without Color | Not applicable: the indicator conveys no state through color — every dot and the container share the same `secondaryText` hue throughout, and which dot is "active" is conveyed by opacity/brightness within that single hue, not by a color-coded distinction that would need a non-color alternative. |

- **low-alpha-contrast**: The container fill (0.08 alpha) and the dimmed dot state (0.3 alpha) are fixed alpha multipliers this component applies over a host-supplied background, and the dot color comes from the active theme palette; the component defines no contrast floor for either, so whether the dimmed dots and container stay distinguishable against a given host background is not checked here.

