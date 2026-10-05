
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | passed | Security |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | partial | Reliability |

Secure-storage passes because `DaemonAIChat.swift` never persists a credential itself — it only reads through the injected `SecretStoring` abstraction (Keychain-backed by default) and forwards the resolved value in memory for the duration of one call, per the Privacy section. Explicit-error-handling is `partial`: every plugin-path failure (load, `buildRequest`, streaming, empty reply) and every guard refusal is a typed, thrown error, but the CLI path passes an error other than `ClaudeCLI.CLIError` through unwrapped (see `cli-foreign-error-passthrough`). No-hardcoded-strings fails because every `ChatError.errorDescription` and every constructed `providerError` message this file authors is an unlocalized English literal (see Localization). Graceful-degradation is `partial`: the CLI path IS a designed fallback for the "no provider configured yet" case, but a CONFIGURED provider's own failure (a guard refusal, a network error, an empty stream) never falls back to the CLI path — it hard-fails with a thrown `ChatError`/`AIGuardError` instead.

`separation-of-concerns` passes because `DaemonAIChat` is a one-shot completion path that delegates configuration lookup to `DaemonProviderResolver`, request description to the plugin, streaming to `PluginTransport` and local-model gating to the inference guard, with the plugin runtime behind an injectable `PluginRuntime` seam. `unit-test-coverage` passes because `DaemonAIChatTests.swift` covers the plugin path (config resolution, ledger values and secrets, stream accumulation, empty reply, transport errors) and the CLI fallback error mapping through that seam, `DaemonAIChatGuardTests.swift` covers the inference guard, and `DaemonLivePluginRuntimeTests.swift` covers the production `.live` runtime's discovery, not-installed, schema-version and unloadable-bundle paths (the successful load of a real plugin binary is deliberately not unit-tested).

