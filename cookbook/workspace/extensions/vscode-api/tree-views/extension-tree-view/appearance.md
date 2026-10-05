
- **Corner radius**: None anywhere in this component.
- **Padding**: Message banner inset 16pt from the container's leading/trailing edges and 8pt from its top edge (half of the 16pt message inset); the tree sits 8pt below the banner when shown, flush with the container's top edge otherwise. Inside a row, the icon/label/caption stack is inset 2pt from the row's leading edge and at most 6pt from its trailing edge, with 4pt spacing between the three pieces.
- **Font**: Not set as literal point sizes in this component. Message banner: tertiary-text role at caption text scale. Row label: primary-text role at body text scale. Row caption: tertiary-text role at caption text scale. All are theme-resolved semantic fonts, not literal sizes.
- **Background**: The container view's fill and the tree's own background both track the `.surface` semantic color; the tree's grid color tracks the `.divider` semantic color.
- **Foreground/Text**: Row icon tinted `.secondaryText`; row label `.primaryText`; row caption and message banner `.tertiaryText`. All theme-resolved semantic tokens, never literal color values.
- **Border**: None drawn anywhere in this component.
- **Shadow**: None drawn anywhere in this component.
- **Min/Max size**: The container view's initial frame is 300×200 points — only the layout system's starting point, not an enforced minimum or maximum. No other size constraint is set by this component; the pane's actual bounds are governed by whatever hosts it, which is out of scope here.

