
- **Role**: Neither the container nor any dot element has an accessibility role set (contrast with the sibling day banner view, which explicitly sets a static-text role); nothing identifies this element to a screen reader.
- **Label**: No accessibility label describing the indicator's meaning (e.g. "Assistant is typing") is set at construction or at any point during animation.
- **Announce state changes**: Neither starting nor stopping the animation posts any accessibility state-change notification, so a screen-reader user is given no indication that the assistant has started or stopped composing a reply.
- **Minimum tap target**: Not applicable — the view has no target-action or click handling of any kind, so the standard [44×44pt tap-target guidance](https://developer.apple.com/design/human-interface-guidelines/layout) does not apply.

