# `@agenticdevelopertoolkit/chrome`

Site-chrome primitives. One component so far: the menu button, and the close
glyph derived from it.

## Why

A burger is three identical bars, and three identical elements do not
reliably render as three identical bars. The bar is a box with a fractional
top — the button sits wherever the header's padding and the root font size
leave it — and the rasteriser rounds each edge to a device pixel on its own,
so a bar's rendered thickness is `round(top + thickness) - round(top)`. At a
2.5px bar on a 5.5px pitch, measured on a phone at three device pixels to the
CSS pixel, the outer two bars came out 8 device pixels thick and the middle
one 7: the middle bar was half a pixel out of phase with its neighbours, and
it showed.

Both the bar's thickness and the PITCH (thickness + gap) are whole numbers of
CSS pixels here, which is what makes the three agree: a whole thickness means
`round(x + n) - round(x)` is exactly `n` wherever the bar starts, and a whole
pitch means all three bars share one fractional offset and so round the same
way. It is a small thing to get right and an easy thing to get wrong twice,
which is the argument for it living in one package rather than in each site.

## Usage

```tsx
import { MenuButton } from '@agenticdevelopertoolkit/chrome'
import '@agenticdevelopertoolkit/chrome/css/base.css'

<MenuButton label="Open menu" aria-expanded={open} onClick={() => setOpen(true)} />
<MenuButton icon="close" label="Close menu" onClick={() => setOpen(false)} />
```

## API

### `<MenuButton>` (client component)

A `<button type="button">` with no text, so `label` is required and becomes
its accessible name. Every other button attribute — `onClick`,
`aria-expanded`, `className`, `type` — passes straight through.

| Prop | Type | Notes |
|---|---|---|
| `icon` | `'menu' \| 'close'` | Three stacked bars, or two of them crossed. Default `'menu'` |
| `label` | `string` | Required; the accessible name |
| `className` | `string?` | Concatenated after `menu-button`, for the skin |

## Theming

The package paints nothing. The bars are `currentColor`, so setting `color`
on the button colours the figure, and the rest is custom properties:

| Property | Default | |
|---|---|---|
| `--menu-size` | `32px` | the button's box, `border-box` |
| `--menu-bar-width` | `16px` | |
| `--menu-bar-thickness` | `2px` | **keep it a whole number of pixels** |
| `--menu-bar-gap` | `3px` | **keep thickness + gap a whole number too** |
| `--menu-hit` | `44px` | the invisible tap target, centred on the button |

```css
.site-header .menu-button {
  color: var(--color-ember);
  border: 1px solid var(--color-hairline);
  border-radius: 8px;
  background: rgba(11, 10, 9, 0.6);
}
.site-header .menu-button:hover {
  color: var(--color-ember-bright);
}
```
