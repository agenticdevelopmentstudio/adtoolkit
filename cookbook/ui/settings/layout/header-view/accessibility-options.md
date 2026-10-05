
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component applies no animation, transition, or motion effect of its own — it is built once, at construction, with no animation wrapping any of it. |
| Increase Contrast | The component sets no Increase Contrast handling of its own. Its text is 11pt caption type in the `secondaryText` role, whose derivation guarantees only a 3.0 minimum contrast — below the 4.5:1 WCAG AA figure for text this small; see **minimum-contrast-ratio** and its Design Decision. |
| Differentiate Without Color | Not applicable: the component conveys no state or meaning through color — it renders exactly one presentation, a caption-styled label, with no color-coded distinction for an alternate cue to replace. |

- **minimum-contrast-ratio**: The title's color MUST come from the theme's
  secondary-text role at the caption text size, and the component MUST NOT
  perform any contrast check or adjustment of its own. That role's
  derivation guarantees only a 3.0 minimum contrast, while this 11pt
  caption text falls under WCAG AA's 4.5:1 small-text figure; whether each
  shipped theme's resolved secondary-text-on-background pair reaches 4.5:1
  is a property of the theme's colors, not of this component.

