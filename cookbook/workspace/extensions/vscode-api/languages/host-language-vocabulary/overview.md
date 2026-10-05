
This component is the production conformer of the language-vocabulary
seam, which the languages bridge calls to answer
`vscode.languages.getLanguages()`. It composes two already-deterministic
halves into one deterministic list: every built-in identifier from the
built-in language catalogue's full language list, in that list's own
order, with the catalogue's default-language identifier appended, followed
by every identifier the contribution point reports that is not already
present. Built-ins lead deliberately: per the component's own
documentation, an extension contributing an id the catalogue already has
is adding a file-extension claim to an existing language, not declaring a
new one, and the built-in entry is the one that was there first. The
identifiers this type returns are this host's own vocabulary, not a
translation into VS Code's spellings.

