
Turns one VS Code extension manifest's `contributes.configuration` block
into the rows a settings panel can render, and every compromise that block
forced along the way. It defines the row's value shapes — an option, a
setting's kind (a six-kind control vocabulary: toggle, text, choice,
number, integer, json), a setting row, and a settings section — a note
record for every schema declaration this host could not honour exactly, a
three-outcome declaration distinguishing "no settings declared," "settings
declared but none survived classification," and "the schema itself could
not be read," and the pure classifying logic that produces them.

This classifier holds no state of its own: nothing in it reads or writes a
setting's stored value, opens a file, or touches a window. That is a
separate contribution point's job — a platform-specific piece that
remembers what was applied per extension and turns a declaration into
actual views. This recipe covers the classifier alone; the extension
manifest and that contribution point are collaborators consulted for
grounding but are out of this recipe's scope.

