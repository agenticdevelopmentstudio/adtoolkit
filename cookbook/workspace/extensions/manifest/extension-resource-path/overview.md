
This component is the single containment check this framework uses for
every path a third-party VS Code-compatible extension declares against a
location inside its own installed directory. Before this component
existed, per its own header comment, the same rule was hand-rolled at four
call sites — a theme contribution's `path`, a theme's own `include`, a
snippet contribution's `path`, and the extension host's `browser` entry
point — and three of the four were missing the escape half of the check,
so the same `../../../.ssh/config` traversal could read arbitrary files
through any of them. A typed escape error is the one failure resolving a
path can raise, carrying both the string the extension declared and the
absolute path it actually resolved to, so a rejection is checkable rather
than a bare boolean. The installed-content-location helper is a second,
narrower concern that happens to live alongside this one: it derives the
two conventions this project's hosts use for user-installed add-ons dropped
beside the app rather than inside it — a per-app Application Support
subdirectory, and a hand-filled home dotfolder — replacing what the plugin
manager's initializer and the app's own extension host had each hand-rolled
and let drift out of step. Every production caller today — a theme-import
loop, a snippet-loading loop, a theme importer's root resolution, the
extension host's entry-point resolution, the extension host installer's
entry-point signature check, and the plugin manager's initializer —
resolves or composes its path through this one component rather than
re-deriving the rule.

