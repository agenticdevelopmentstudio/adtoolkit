
- **SwiftUI**: There is no bundler-level, text-substitution build step in a
  compiled Swift app, so the build-time-flag-vs.-server-side-check split has
  no direct motivation. Model the allowlist type as a
  `CaseIterable enum: String { case local, testing, staging }` and replace
  both exports with one function, `isDevDeploymentEnv(_ env: String?) ->
  Bool { env.flatMap(DevDeploymentEnv.init(rawValue:)) != nil }`, read from
  `ProcessInfo.processInfo.environment["DEPLOYMENT_ENV"]`. Keep the fail-closed
  contract (an unrecognized or missing value returns `false`) rather than
  inverting to `!= "production"`.
- **Compose**: `enum class DevDeploymentEnv { LOCAL, TESTING, STAGING }` with
  a `companion object` `fromEnv(env: String?): DevDeploymentEnv?` doing an
  exact, case-sensitive lookup against the enum's declared names (not a
  case-insensitive `equalsIgnoreCase`, to preserve the source's case-sensitive
  fail-closed behavior). Gradle build variants (`buildConfigField`) are the
  build-time-inlined analog of `NEXT_PUBLIC_*`, resolved per build
  type/flavor at compile time rather than per module-load; there is no
  Kotlin/Gradle equivalent of the chunk-gate contract's dynamic-load
  concern, since Gradle's dead-code elimination (R8/ProGuard) works on
  compiled bytecode, not on textual environment-variable substitution.
- **React/Web**: (source) `packages/web/packages/adh-registry/src/deployment-env.ts`,
  with its own tests in `src/__tests__/deploymentEnv.test.ts`; exposed
  outside the package through the `./deployment-env` subpath declared in
  `package.json`'s `exports`, and re-verified from outside the package by
  `@agentic-toolkit/adh`'s `productionBundleGates.test.ts` and, across a repo
  boundary, by `adhbackend`'s `src/adh/test/themeSurfaceEnv.test.ts`. What is
  specific to this platform: the entire build-time-flag-vs.-server-side-check
  split, and the whole chunk-gate contract, exist only because Next.js/webpack
  inlines `process.env.NEXT_PUBLIC_*` as text before bundling and then
  performs dead-code elimination purely on syntactic literal comparisons — a
  constraint with no equivalent on a platform without build-time text
  substitution. The chunk-gate contract's subpath-specifier rule exists
  because a package's own bundler configuration — here, tsup's
  `splitting: false` — can otherwise inline a relative import's code into
  the same output file, erasing the module boundary the gate depends on; a
  package-subpath import is what keeps that boundary intact. Separately,
  `isDevDeploymentEnv` is declared as a TypeScript type predicate (`env is
  DevDeploymentEnv`), a compile-time-only fact: it does not change what the
  function returns at runtime, only that code branching on a `true` result
  narrows the static type of its argument from `string | null | undefined`
  to the literal union `'local' | 'testing' | 'staging'` for the rest of
  the type-checker's analysis of that branch. It has no dedicated runtime
  test in this checkout and no corresponding entry in the Conformance Test
  Vectors table above for that reason; a TypeScript port that keeps this
  contract should declare the equivalent type-predicate return annotation.
- **AppKit / UIKit**: Same approach as SwiftUI — a `CaseIterable` enum (or a
  small `Set<String>` allowlist) behind one pure function; AppKit/UIKit code
  would call it identically to SwiftUI code, since this is UI-framework-agnostic
  logic with no view dependency. There is no chunk-gating concern the way
  there is in a Next.js bundle, because Xcode performs no build-time textual
  substitution of environment variables followed by dead-code elimination.
- **WinUI 3**: This is the platform this recipe exists to steer. Read the
  deployment tier from an environment variable at startup
  (`Environment.GetEnvironmentVariable("DEPLOYMENT_ENV")`, or an app-config
  setting for a packaged MSIX app), and expose the equivalent of the
  allowlist as an `enum DevDeploymentEnv { Local, Testing, Staging }`
  with a static `IsDevDeploymentEnv(string? env)` method doing the same
  exact, case-sensitive, fail-closed membership test — never `!= "production"`.
  Because a WinUI 3/MSIX app has no bundler-level, build-time text
  substitution and dead-code-elimination step analogous to webpack's
  `NEXT_PUBLIC_*` fold, the build-time-flag-vs.-server-side-check
  duplication and the chunk-gate contract (inlined comparisons, package-subpath
  imports) have no direct equivalent; a WinUI 3 port needs only ONE gate, most
  naturally exposed as a `Lazy<bool>` (no `Task`/`async` needed — this is a
  synchronous environment read) evaluated once at app startup and passed down
  to whichever XAML `Page`/`Frame` decides whether to show dev-only UI (a
  settings toggle, a debug menu item), gated with an `x:Bind`/`Visibility`
  binding rather than a dynamic module load. If a future WinUI 3 build
  genuinely needs to keep an entire dev-only page or assembly out of the
  shipped MSIX package, that is a packaging/project-reference concern (a
  project reference included only for Debug/Staging build configurations via
  a conditional `<ItemGroup Condition="...">` in the `.csproj`), not a
  runtime import-site gate — WinUI 3 has no equivalent of a JavaScript
  dynamic-chunk load boundary.

