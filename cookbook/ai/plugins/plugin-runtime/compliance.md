
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | passed | Security |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

Notes: separation-of-concerns passes because the component splits into three
independent responsibilities — plugin lifecycle (`AIPluginsCoordinator`),
configuration modeling and persistence (`AIProviderConfigStore`,
`AIProviderResolver`, `AIProviderDefaults`, `AIProviderMigration`,
`PluginConfigStore`), and conversation driving (the two
`ChatConfigProvider` + chat-engine pairs) — and none reaches into another's
storage. unit-test-coverage passes because the conformance vectors trace to
`LocalChatSessionTests`, `AIProviderConfigStoreTests`,
`AIProviderResolverTests`, `AIProviderMigrationTests`, and
`AIProviderDefaultsTests`, which exercise streaming, seeding, resolution,
migration, and first-run defaults without a live provider. secure-storage
passes because every `.secret` field is persisted through a
`UserSetting<String>` constructed with `isSecure: true`, so credentials land
in the Keychain and never in plain user defaults (see Privacy).
input-sanitization and explicit-error-handling are partial because
`MCPChatToolSource.callTool` decodes the model's `argumentsJSON` with `try?`
and forwards `nil` arguments on a decode failure instead of reporting a tool
error — see mcp-tool-source-argument-validation and its Design Decision — while
the other failure paths (no configured provider, unknown tool, a throwing
MCP call) surface as explicit `ChatError` or tool-error text.
no-hardcoded-strings fails because the user-facing error strings listed
under Localization are English literals with no localization mechanism.

