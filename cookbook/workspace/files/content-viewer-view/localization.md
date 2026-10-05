
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `Select a file to view its details` (a localizable string literal) | Select a file to view its details | Placeholder message shown with no selection |
| `Path:` (a localizable string literal) | Path: | Grid row label |
| `Size:` (a localizable string literal) | Size: | Grid row label |
| `Modified:` (a localizable string literal) | Modified: | Grid row label |
| `Type:` (a localizable string literal) | Type: | Grid row label |
| `Extension:` (a localizable string literal) | Extension: | Grid row label |
| `Items:` (a localizable string literal) | Items: | Grid row label |
| (none — hardcoded literal) | Directory | Type description for a directory |
| (none — hardcoded literal) | Package | Type description fallback for a package with no configured display name |
| (none — hardcoded literal) | Swift Source File / JSON File / Markdown Document / Text File / Property List / Entitlements File / Xcode Project / Xcode Workspace / PNG Image / JPEG Image / SVG Image / GIF Image / Shell Script / Zsh Script / Bash Script / Python Script / JavaScript File / TypeScript File / CSS Stylesheet / HTML Document / YAML File / TOML File / Git Ignore Rules | Type description for a file, by recognized extension (see `type-description-known-extension`) |
| (none — hardcoded literal) | `<EXTENSION> File` / File | Type description fallback for an unrecognized or absent extension |

The seven fixed labels are passed as string literals that the platform treats as localizable keys: they are looked up in the bundle's string table and fall back to the literal when no translation exists. The type descriptions (`Directory`, `Package`, the per-extension names, and the `<EXTENSION> File` fallback) are computed string values rendered verbatim with no lookup: these are hardcoded English strings with no localization of their own.

