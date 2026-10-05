
**Decision**: the plugin configuration stores configuration as a flat
string-keyed dictionary of strings with three convenience accessors
(`apiKey`, `baseURL`, `model`), rather than a strongly-typed shape with one
field per plugin-declared value.
**Rationale**: (Swift implementation) a plugin's settings schema (its
`descriptor.json`, described alongside `AIPlugin.swift`) is host-resolved
data, not compile-time-known fields — a stringly-typed bag is the only
shape that can carry an arbitrary, plugin-declared field set without this
contract knowing every plugin's schema in advance. Callers SHOULD use the
literal keys `apiKey`, `baseURL`, and `model` for those conventional
fields, since the plugin configuration performs no key aliasing or
normalization — a caller that stores an API key under a different key name
will find `apiKey` returns nothing.
**Approved**: pending

**Decision**: the chat context's `maxTokens` defaults to `4096` with no
enforced minimum or maximum.
**Rationale**: this contract treats `maxTokens` as an opaque budget number
to forward to whichever provider the plugin targets; per the Edge Cases
entry above, no validation exists anywhere in the current call chain (this
contract, the request-building step, or any of the plugins implemented
today), so `4096` is a convenience default rather than a validated floor.
**Approved**: pending

