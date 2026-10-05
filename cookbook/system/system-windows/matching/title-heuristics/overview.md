
Window matching heuristics are the five built-in per-app title parsers that
ship with the system-window matching feature: one each for Xcode, Warp,
Brave, VS Code and Terminal. Each one knows the window-title format of one
application family and turns a raw window title into the stable, identifying
part of it — a project name, a workspace name, a page title, a directory, or
a running command — or an absent value when no useful pattern can be
extracted.

They are pure, stateless value types. A heuristic registry registers them
(in the order Xcode, Warp, Brave, VS Code, Terminal) and looks one up by the
window's owning app name; the window matcher then calls the fingerprint
operation when it fingerprints a window and the pattern-extraction operation
when it scores a live window against a stored fingerprint. Use this recipe
to port the title-parsing rules; the registry, the custom user rules, and
the matcher's scoring are outside it.

The shared pieces the heuristics build on are the heuristic contract (with
its default recommended-strategy and fingerprint operations) and the
title-parser helper that splits a title on the em-dash or en-dash separator.

