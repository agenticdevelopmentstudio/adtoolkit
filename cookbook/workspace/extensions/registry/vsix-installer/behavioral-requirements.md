
- **injected-install-directory**: `VSIXInstaller` MUST store `installDirectory`
  as an injected `URL` rather than deriving it internally, because the tier
  this type lives in cannot import `AppStorageLocation`, and because a test
  that installs into a real user's extensions directory would not be a test.
- **default-host-version**: `init`'s `hostVersion` parameter MUST default to
  `ExtensionRegistry.declaredVSCodeVersion`, which equals `SemanticVersion(major:
  1, minor: 138, patch: 0)` (66–68; `ExtensionRegistry.swift`).
- **injected-file-manager**: `init`'s `fileManager` parameter MUST be a
  shareable closure returning a file-system handle (defaulting to the platform's default file-system handle), never a
  stored handle instance, because a file-system handle is not safe to share across threads and
  this type is; every file operation MUST read the file-system handle through this
  closure.
- **sendable-value-type**: `VSIXInstaller` MUST be an immutable value type
  that is safe to share across threads and concurrency domains, usable concurrently from any thread or execution context without additional
  synchronization for its own construction and property access, because its
  only stored properties are an immutable `URL`, an immutable
  `SemanticVersion`, and an immutable shareable closure.
- **registry-install-order**: `install(_:using:)` MUST decide installability
  from the record's metadata, then decide verification-artifact completeness
  from the record's metadata, before downloading anything; only after both
  checks pass MUST it download the archive and whichever verification
  artifacts the record named.
- **registry-installability-gate**: `install(_:using:)` MUST throw
  `VSIXInstallError.registryVersionUnusable(installability)` when
  `detail.installability(forHostVersion: hostVersion)` is not `.installable`,
  without making any request.
- **registry-requires-universal-build**: `install(_:using:)` MUST throw
  `VSIXInstallError.registryVersionUnusable(.noUniversalBuild)` when
  `detail.universalDownloadURL` is `nil`, without making any request.
- **signature-pair-completeness**: `install(_:using:)` MUST throw
  `VSIXInstallError.verificationIncomplete(published:missing:)`, before
  downloading the archive, when the record names exactly one of
  `signatureURL`/`publicKeyURL` and not the other — `verificationIncomplete(
  published: "signature", missing: "publicKey")` for a signature with no key,
  `verificationIncomplete(published: "publicKey", missing: "signature")` for a
  key with no signature.
- **artifact-fetched-only-if-named**: `install(_:using:)` MUST fetch
  `sha256URL`, and MUST fetch both `signatureURL` and `publicKeyURL` together,
  only when the record names each one; an artifact the record names but
  `client` cannot serve MUST propagate as `client`'s own thrown error, carrying
  the URL that failed.
- **blocking-verification-hop**: `install(_:using:)` MUST run archive
  verification (`VSIXArchive.verify`) and the local install
  (`install(archive:verification:expectedIdentifier:source:)`) inside
  `BlockingWork.run`, on a GCD global queue, rather than directly on the
  calling `async` context or inside `Task.detached` — because both steps are
  synchronous and blocking (a SHA-256 over up to 512 MB, then a write and a
  `ditto` invocation that can hold a thread for up to 124 seconds), and a
  detached task still occupies a cooperative-pool thread for the whole of that
  (`BlockingWork.swift`).
- **local-install-entry-point**: `install(archive:verification:
  expectedIdentifier:source:)` MUST be usable both as the tail of the registry
  flow above and as the sole entry point for archive bytes with no registry
  provenance (a user-supplied `.vsix`), with `expectedIdentifier` defaulting to
  `nil` for the latter case.
- **scratch-directory-lifecycle**: `install(archive:...)` MUST create a
  uniquely named scratch directory under `fileManager.temporaryDirectory`
  (`vsix-install-<UUID>`), and MUST remove it via `defer` on every exit path,
  successful or not.
- **archive-expansion**: `install(archive:...)` MUST write `archive` to
  `extension.vsix` inside the scratch directory and expand it with
  `VSIXArchive.expand` into an `expanded` subdirectory before reading anything
  from it.
- **payload-directory-required**: `install(archive:...)` MUST throw
  `VSIXInstallError.noPayloadDirectory` when `VSIXArchive.payloadDirectory(in:
  expanded)` does not exist — a zip that is not a `.vsix`.
- **manifest-read-and-localized**: `readManifest(in:)` MUST read
  `<payload>/package.json`, run its bytes through
  `ExtensionManifestLocalization.localize(_:forManifestIn:)` to resolve
  `%key%` placeholders against the payload's own nls tables, then through
  `JSONCPreprocessor.jsonData(from:)`, before decoding it as `ExtensionManifest`
  with a plain `JSONDecoder`.
- **manifest-unreadable**: `readManifest(in:)` MUST throw
  `VSIXInstallError.manifestUnreadable` when `package.json` cannot be read as
  `Data`.
- **manifest-malformed**: `readManifest(in:)` MUST throw
  `VSIXInstallError.manifestMalformed(String)`, carrying the decoder's
  `localizedDescription`, when the (localized, preprocessed) bytes do not
  decode as `ExtensionManifest`.
- **identity-claim-checked**: `install(archive:...)` MUST throw
  `VSIXInstallError.identityMismatch(claimed:found:)` when `expectedIdentifier`
  is non-`nil` and differs from the decoded `manifest.identifier`, before any
  further check runs — a registry claim the archive's own manifest does not
  bear out.
- **engine-range-checked**: `install(archive:...)` MUST throw
  `VSIXInstallError.engineRangeUnreadable(manifest.engines.vscode)` when
  `VSCodeEngineRange(manifest.engines.vscode)` fails to parse, and MUST throw
  `VSIXInstallError.engineIncompatible(manifest.engines.vscode, host:
  hostVersion.description)` when the parsed range does not accept
  `hostVersion` — both before the destination directory is computed or created.
- **identity-fields-validated**: `install(archive:...)` MUST call
  `requireSafeComponent` on both `manifest.identifier` and `manifest.version`,
  throwing `VSIXInstallError.unsafeIdentity(field:value:)` when either fails
  `ExtensionIdentityComponent.isSafe`, before either value becomes a directory
  name component, on every install path — `expectedIdentifier` above guards
  only one field on only the registry path, and `version` is compared with
  nothing else on any path (343–347;
  `ExtensionIdentityComponent.swift`).
- **directory-naming-convention**: `VSIXInstaller.directoryName(identifier:
  version:)` MUST return `"\(identifier)-\(version)"` — the layout the
  Marketplace installer writes — as pure string interpolation with no escaping
  and no validation of its own; the constraint that makes the result safe
  lives entirely in the caller's prior call to `requireSafeComponent`, not in
  this function.
- **destination-containment-double-checked**: `install(archive:...)` MUST
  independently verify, after building `destination`, that
  `ExtensionResourcePath.canonicalChild(directoryName, of: installDirectory)`
  is contained in `ExtensionResourcePath.canonicalDirectory(installDirectory)`,
  throwing `VSIXInstallError.unsafeIdentity(field: "identifier", value:
  destination.lastPathComponent)` when it is not — a check over the actual
  resolved path, distinct in kind from the string-level
  `identity-fields-validated` check above it, because a future change to
  `directoryName` that joined its parts differently would slip past the first
  and be caught here.
- **install-directory-created**: `install(archive:...)` MUST create
  `installDirectory`, with intermediate directories, before scanning it or
  writing into it — a first install into a fresh home MUST succeed, not be
  treated as an edge case (test `createsTheInstallDirectory`).
- **recovery-runs-before-scan**: `install(archive:...)` MUST call
  `recoverInterruptedInstalls()` before computing superseded directories or
  moving anything into place, so an aside a previous crash left behind is
  visible to the supersede sweep rather than invisible and unreclaimed.
- **reinstall-idempotent**: `install(archive:...)` MUST succeed, not throw a
  conflict, when the archive being installed is the same identifier and
  version already present at `destination` — the existing directory MUST be
  replaced rather than left alone, because its bytes are unproved and it may
  be a half-written tree an earlier attempt died inside, while the incoming
  bytes have already passed verification (test
  `reinstallIsIdempotent`).
- **supersede-by-manifest-identity**: `otherInstallDirectories(claiming:
  besides:)` MUST list every directory in `installDirectory` other than
  `destination`, skipping hidden entries, and MUST match a candidate by
  decoding its own `package.json` and comparing `manifest.identifier` — never
  by matching the candidate's folder name against any naming convention — so a
  hand-installed extension or a dev checkout named however its author named
  it is still recognized as superseded (test
  `supersedesAHandNamedDirectory`).
- **supersede-non-fatal-removal**: `install(archive:...)` MUST still return a
  successful `VSIXInstallation` when a superseded directory cannot be removed,
  logging the failure rather than throwing, because the new version is already
  in place and loadable by that point and reporting the install as failed
  would be false (test
  `anUnremovableSupersededCopyStillInstalls`).
- **move-into-place-atomicity**: `moveIntoPlace(_:to:)` MUST move an existing
  `destination` aside before moving the new payload in, never delete it
  first, so that a failure of the second move can restore the first; when
  `destination` did not previously exist, a failed move MUST throw
  `VSIXInstallError.couldNotInstall(reason)` directly with no aside step at
  all.
- **move-into-place-rollback**: `moveIntoPlace(_:to:)` MUST attempt to move
  the aside back to `destination` when the payload move fails and a previous
  copy existed; on a successful rollback it MUST throw
  `VSIXInstallError.couldNotInstall(reason)` naming only the original failure;
  on a failed rollback it MUST log the rollback failure at `error` level and
  throw `VSIXInstallError.couldNotInstall` naming both the original failure
  and that the previous version could not be put back, together with the
  aside's last path component.
- **aside-cleanup-on-success**: `moveIntoPlace(_:to:)` MUST attempt to remove
  the aside with `try?` once the new payload is successfully in place,
  swallowing any removal failure rather than surfacing it as part of a
  successful install.
- **aside-naming**: the aside a replaced directory is moved to MUST be named
  `.<destination.lastPathComponent>.replacing-<UUID>` — a leading dot so that
  `otherInstallDirectories` and `ExtensionRegistry.scan`, both of which pass
  `.skipsHiddenFiles`, do not see the second copy of the identifier that
  exists for the moment between the two renames.
- **recovery-sweep-scope**: `recoverInterruptedInstalls()` MUST list
  `installDirectory`'s contents with no hidden-file filtering (the opposite of
  every other listing in this file), and for every entry whose name
  `Self.replacedName(ofAside:)` recognizes, MUST either remove the aside (when
  its replaced destination already exists) or move the aside back to that
  destination (when it does not).
- **recovery-non-aside-entries-untouched**: `Self.replacedName(ofAside:)` MUST
  return `nil`, leaving the entry alone, for any hidden name that does not
  carry both the leading-dot prefix and the `.replacing-<nonce>` marker with a
  non-empty replaced name — an ordinary dotfile such as `.DS_Store` MUST NOT be
  touched by a recovery sweep (test
  `anUnrelatedHiddenEntryIsLeftAlone`).
- **recovery-failure-logged**: `recoverInterruptedInstalls()` MUST log, at
  `error` level, a failure to remove or restore a recognized aside, and MUST
  leave that aside exactly where it is rather than deleting it — it may be the
  only surviving copy of the extension.
- **recovery-idempotent**: `recoverInterruptedInstalls()` MUST be safe to call
  when no install is in progress and MUST be safe to call repeatedly, because
  it acts only on entries matching the aside naming convention and a live
  `moveIntoPlace` holds its aside for both of its renames on one synchronous call path
  with no hop to another execution context.
- **installation-record-shape**: On success, `install(archive:...)` MUST
  return a `VSIXInstallation` carrying `identifier`, `version`, `displayName`,
  `directory` (the final `destination`), `verification`, `source`,
  `supersededDirectories` (every directory this call removed or failed to
  remove), and `runnableHere`, all taken from the decoded manifest and the
  call's own inputs.
- **runnable-here-computed**: `VSIXInstallation.runnableHere` MUST equal
  `manifest.browser != nil || manifest.main == nil` — `true` for a web
  extension with a `browser` entry point or for a declarative-only extension
  with no entry point at all, `false` only for an extension that declares
  `main` and no `browser`; a `false` value MUST NOT be treated as a failed
  install, since the extension's declarative contributions still work (574–584; test `runnableHereFollowsTheEntryPoint`).
- **install-source-shape**: `VSIXInstallation.Source` MUST be either
  `.registry(String, version: String)` (the `<namespace>/<name>` and version
  asked for) or `.localFile(URL)` (a `.vsix` the caller supplied), and
  `install(_:using:)` MUST always construct the former from `detail.namespace
  + "/" + detail.name` and `detail.version`.
- **directory-name-not-independently-safe**: `directoryName(identifier:
  version:)` and the historical doc comment on it MUST be understood as pure
  joining that guarantees nothing on its own — a prior version of this
  function's documentation claimed npm-level constraints on `name` and
  `publisher` that do not exist, since nothing in this path runs npm and
  `publisher` is not an npm field; the actual constraint is
  `identity-fields-validated` and `destination-containment-double-checked`
  above, in the caller.
- **request-safe-component-error**: `requireSafeComponent(_:field:)` MUST
  throw `VSIXInstallError.unsafeIdentity(field:value:)` naming the actual
  field and the actual (unsafe) value, rather than a generic failure, because
  the person reading the message is the one who needs to see what the archive
  claimed.
- **logging-conformance**: `VSIXInstaller` MUST conform to `Loggable`,
  declaring a static logger readable from any execution context, giving it
  category `"VSIXInstaller"` under whatever subsystem `Bundle.main.
  bundleIdentifier` resolves to (`"nil"` when there is none) (`Loggable.swift`).
- **case-folded-manifest-identifier**: `manifest.identifier`, which
  `directory-naming-convention` and every identity check above consume, MUST
  already be the case-folded `publisher.name` (or bare `name` with no
  publisher) that `ExtensionManifest.identifier` computes — `VSIXInstaller`
  itself performs no case-folding of its own
  (`ExtensionManifest.swift`).
- **concurrent-install-ordering**: Concurrent install calls sharing one install directory MUST be expected to interleave: no lock or other serialization serializes them (the installer is a plain stateless value), so each call independently runs crash recovery, the supersede scan, the move into place, and superseded-directory cleanup against the same directory tree, and the installer defines no ordering, mutual exclusion, or detection of that overlap.

