
The JSONC preprocessor turns JSONC — JSON with `//` and `/* … */` comments
and trailing commas, the dialect VS Code writes its own configuration files
in — into strict JSON that an ordinary JSON decoder accepts. It holds no
state and performs no I/O of its own: every call receives its input as a
parameter (text, or raw bytes in an unknown encoding) and returns a value or
throws. It was extracted from a color-theme importer's own private copy of
this logic once a second caller — a language-snippet file reader — needed
the same JSONC-reading behavior, because two readers of the same dialect
must not drift apart. In this repository it is also used by an
extension-manifest localization component, an extension registry, and an
extension-package installer to read extension manifests, their
localization tables, and VS Code color themes and snippet files — all files
a third party (an extension or theme author, or an editor on another
platform) authored and saved in whatever encoding and comment style VS Code
itself tolerates.

