
The Group View is a settings-layout container that draws a settings group
the way a system settings app draws one — a caption sitting outside and
above a rounded card, and inside the card one padded row per setting with a
hairline between them. The caption is a separate view (a Header View by
default, or any caller-supplied view) positioned above the card, which holds
a vertical stack of rows. Each row added to the group is wrapped in an
internal row wrapper that owns the row's own padding and the separator
above it. A row whose content can report when it hides itself lets the
Group View collapse that row's padding and hairline when the content hides
itself, so a dismissed hint or a conditionally-hidden group member does not
leave a padded blank band or a stray divider behind — the same self-hiding-
content contract the sibling Conditional View and Dismissible Hint View
recipes fulfill for that reason.

