
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| Disclosure | agenticdevelopertoolkit://recipes/disclosure | The collapsed-by-default Danger-zone container; its open/closed state is controlled by the section so the red accent tracks whether it is disclosed | yes | Open state bound to the section's disclosed state; red styling and title color applied only while disclosed; carries the warning glyph in its title |
| Button | agenticdevelopertoolkit://recipes/button | The disclosed Delete trigger, and the dialog's Cancel/Yes/Permanently-Delete actions | yes | Uses the shared button ingredient's destructive-ghost style for Delete and Yes, a neutral style for Cancel, and its strongest destructive style for the final Permanently Delete action |
| Dialog | agenticdevelopertoolkit://recipes/dialog | The modal that carries the two-phase confirm (warn → type-to-confirm) | yes | Open state controlled by the section; its close control is hidden while busy; uses the shared header/title/description/footer structure |

Composed shared primitives without their own recipe domains: a text input (the
type-to-confirm field, which autofocuses and disables autocomplete and spell-check),
a label (visually hidden, for that input), and the trash/warning/archive glyphs.

The frontmatter `ingredients` field points to `agenticdevelopertoolkit://recipes/…`
domains rather than `ingredients/…` domains because Disclosure, Button, and
Dialog are each documented as their own recipe in that toolkit, not as bare
ingredients — this recipe composes those recipes, it doesn't restate them as
ingredients of its own.

