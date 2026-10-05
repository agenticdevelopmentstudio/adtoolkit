
`VSCodeEngineRange` is `AgenticToolkitCore`'s parser and evaluator for a VS
Code extension manifest's `engines.vscode` field. Per its own doc comment it
is a deliberate port — not an interpretation — of VS Code's own
`extensionValidator.ts` (`isValidVersionStr`, `parseVersion`,
`normalizeVersion`, `isValidVersion`), pinned at the commit recorded in
`whippet/docs/planning/vsc-extensions-upstream-pin-manifest.md`, because
`engines.vscode` *looks* like an npm semver range and is not one: an npm
reading rejects 48 of the 198 web extensions among the 600 most-downloaded on
Open VSX (per `Scripts/openvsx_engine_survey.py`) that VS Code itself runs.
The grammar it implements is exactly `(^|>=)?(digit-run or x).(digit-run or
x).(digit-run or x)` optionally followed by a `-` pre-release suffix, plus
the bare `*`; every other npm shape (`~`, `>`, `<`, `||`, a hyphen range, a
two-component version) is outside the grammar and fails to parse. A
requirement is represented as three bases — `majorBase`, `minorBase`,
`patchBase` — each paired with its own must-equal flag, plus an `isMinimum`
flag for a `>=` range; an operator's only job is to clear must-equal flags,
never to compute a ceiling, and a version below 1.0.0 that has any flag
cleared is treated as compatible with every 1.x version, while a fully
pinned sub-1.0.0 version is not. `minimumVersion` reports the requirement's
declared floor and `isUnconstrained` reports whether the range makes no
version claim at all (`*`, or an all-`x` range) — a distinction
`minimumVersion` alone cannot draw, because both `*` and a literal `0.0.0`
read as a floor of 0.0.0.

Four production call sites consume it today, all in
`AgenticToolkitCore`: `ActivationEventMatcher.init(manifest:)` reads
`minimumVersion` and `isUnconstrained` to decide whether a manifest's engine
grants VS Code 1.74's implicit-activation-from-`contributes.commands` rule;
`ExtensionRegistry.load(from:)` (`ExtensionRegistry.swift`) and
`VSIXInstaller`'s install path (`VSIXInstaller.swift`) each parse the
manifest's declared engine and call `accepts(_:)` against
`ExtensionRegistry.declaredVSCodeVersion` (1.138.0) to decide whether the
extension may load at all, reporting `.engineRangeUnparsable`/
`.engineRangeUnreadable` when the string does not parse and
`.engineIncompatible` when it parses but is not accepted; and
`OpenVSXCatalog.OpenVSXExtensionVersion.installability(forHostVersion:)`
runs the same two checks before a registry entry's `.vsix` is downloaded, so
that an incompatible or unparseable engine is refused before any network
transfer.

