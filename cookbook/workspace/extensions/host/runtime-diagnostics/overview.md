
Three related pieces of runtime diagnostics that make two otherwise-invisible
facts about a running build observable. The JIT availability value answers,
from this process's own code-signing entitlements, whether a JavaScript
engine in this process will compile code or silently fall back to its
interpreter — a degradation the engine never surfaces on its own. This
diagnosis is inherently about a macOS-specific security mechanism (the
hardened runtime and its per-app entitlements) with no cross-platform
equivalent; see Platform Notes. The divergence catalogue is a fixed,
built-in list of six places this app deliberately does less than VS Code,
each entry carrying what VS Code does, what this app does instead, why, and
whether it can be observed happening at runtime. The divergence ledger is
the process-wide, thread-safe tally of which catalogue entries a real
extension session actually trips, published live to any subscriber, such as
a language-server settings panel. All three exist so that a narrowing
recorded only in a source comment — or a degradation with no symptom at all
— becomes something a person or a panel can actually see.

