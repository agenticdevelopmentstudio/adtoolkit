
The activation event matcher is the parser and query engine for a VS Code
extension manifest's `activationEvents` array. It exists so a host does not
re-parse the same five prefixes at every call site. Together with its
supporting concepts it is the whole activation-matching contract: an
activation event parses one manifest entry into a typed kind; an activation
trigger names a thing that just happened in the host (startup finished, a
document opened, a command invoked, a webview panel restored, a
contributed view shown, or a workspace scan completed); a workspace scan is
one directory walk's paths, decomposed once for reuse across every
extension checked against it; a glob pattern is a backtracking matcher for
`workspaceContains:` globs; and the activation event matcher itself, built
once per installed extension from its manifest, answers whether it matches
any given activation trigger and also implements VS Code 1.74's "implicit
activation from `contributes.commands`" rule. The extension host installer
is the sole production caller today: it builds one matcher per extension
host installation at construction and queries it repeatedly as startup,
document-open, command-invocation, view-shown and workspace-scan triggers
occur.

