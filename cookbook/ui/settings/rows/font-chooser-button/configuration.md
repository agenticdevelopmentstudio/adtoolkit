
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `width` | optional numeric value | none (plain default construction) | Fixes the button to this width via one layout constraint, for a button that must line up with others in a grid column. Omitted (or absent), the button takes the width its title wants and gives it up first when its row is squeezed (see **yields-width-under-compression**). |
| `font` (given to the component) | optional font value | none (drawn at construction) | The face to draw the title in and what the font-selection UI opens on; a `nil` value draws the title in the system font. |
| `title` (given to the component) | string | `"System"` (drawn at construction) | What the button reads; the caller owns the wording (see **Label**, above). |
| change callback | function reference (optional) | none | Invoked with the font the user picked in the font-selection UI. |

