
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [test-pyramid](agenticdevelopercookbook://compliance/best-practices#test-pyramid) | partial | Best Practices |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | failed | Reliability |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | passed | Privacy and Data |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |

`separation-of-concerns` passes because `PluginTransport` is, by its own doc comment, "the one place in the system that performs networking or spawns a process" — every `AIPlugin` conformer only describes and decodes. `explicit-error-handling` passes because every failure path maps to a named `TransportError` case or is deliberately passed through unwrapped (`raw-error-passthrough`), with no silent catch-and-ignore anywhere in the source. `test-pyramid` is partial because `PluginTransportTests.swift` and `PluginTransportFramingTests.swift` exercise the command transport thoroughly with hermetic `/bin/sh` children, but the given sources contain no equivalent unit test for `runHTTP`. `input-sanitization` is partial because `runHTTP` and `runCommand` forward `headers`, `body`, `executableURL`, `arguments`, and `environment` to `URLRequest`/`Process` without any validation of their own — the open question of whether that should happen here rather than in the plugin or the host is the same one the sibling `AIRequestSpec` recipe records. `fault-tolerance` passes because every defined failure mode (non-2xx status, nonzero exit, invalid response, budget expiry) degrades to a typed, thrown error rather than a hang or a crash. `error-recovery` fails because, per the `single-attempt` Design Decision above, no failure is ever retried or recovered from within this component. `no-pii-in-logs` passes trivially, since the component performs no logging at all. `string-externalization` fails because the four literals under Localization above are hardcoded English with no string-catalog key.

`unit-test-coverage` passes because `PluginTransportTests.swift` covers the wall-clock timeout, a command finishing within budget, stdin delivered byte for byte, a non-zero exit becoming a command failure with stderr, `describeError` receiving stderr, and environment replacement, and `PluginTransportFramingTests.swift` covers newline framing with a trailing fragment.

