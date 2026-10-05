
This component is the model of a VS Code `package.json` used by this host.
It has no visual surface of its own: it is a pure, synchronous decode/encode
layer — everything downstream that reads to install themes, snippets,
languages, commands, keybindings, menus, settings, views, view containers,
and (later) language-model tools comes from the contributions value this
component decodes. Its defining discipline is asymmetric strictness: the
extension's `name`, `version`, `engines.vscode`, and the `contributes`
block's own shape are the extension's non-negotiable identity, and a
manifest missing or misspelling any of them fails to decode entirely;
everything else — every `contributes.*` array element, every
keyed-dictionary location, every optional scalar field — is decoded with
element- or field-level isolation, so one malformed theme, command, or
configuration property never costs its siblings. A shared lenient-decoding
helper implements that isolation once, used by every `contributes.*`
collection, and a typed decoding-failure record — never itself re-encoded —
is how a caller learns what, if anything, one decode attempt had to drop.

