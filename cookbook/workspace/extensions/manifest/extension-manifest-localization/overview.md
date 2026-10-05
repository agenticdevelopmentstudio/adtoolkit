
This component resolves the `%key%` placeholders a VS Code `package.json`
uses in place of the strings a person reads. An extension that ships
translations does not put English in `package.json` at all — it writes
`"displayName": "%name%"` and puts the English in `package.nls.json` beside
it, the German in `package.nls.de.json`, and so on. The localization
function is the single entry point both of the manifest's readers call
before decoding — the component that reads an installed extension's
manifest, and the component that reads a manifest it is about to install —
so translation resolution happens exactly once, at the one place the bytes
become a decoded manifest, rather than at each place a manifest string is
later displayed. A missing, unreadable, or malformed table never fails the
resolve: it costs the extension its translations and nothing else.

