
- **Reduce Motion**: Supported: presenting and dismissing the overlay
  animate only opacity (a 0.2s fade), duration `fadeDuration`; nothing
  moves, scales, or slides. A cross-fade is the substitute [the Motion
  guidance for reduced
  motion](https://developer.apple.com/design/human-interface-guidelines/motion)
  recommends when Reduce Motion is on, so no separate Reduce Motion path is
  needed. A port keeps the fade opacity-only.
- **Increase Contrast**: Not applicable — this file chooses no color values
  of its own; the backdrop's appearance is entirely the platform's own
  system material rendering, not anything this view controls.
- **Differentiate Without Color**: Not applicable — the base view conveys no
  state (presented, dismissing) via color at all; presence or absence from
  the view hierarchy and the alpha fade are its only signals, neither of
  which is a color distinction.

