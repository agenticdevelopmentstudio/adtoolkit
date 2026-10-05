---
id: 2B552BDE-D0BD-425A-9E79-FC624B52F516
title: "Claude OAuth Credential"
domain: adtoolkit://cookbook/foundation/claude-accounts/claude-o-auth-credential
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The four-part OAuth credential Claude Code keeps for one account, carried as one value so rotation replaces all parts together."
platforms:
  - swift
  - macos
tags:
  - foundation
  - claude-accounts
  - oauth
  - credentials
depends-on: []
related:
  - adtoolkit://cookbook/foundation/claude-accounts/claude-credential-kind
references: []
approved-by: ""
approved-date: ""
---

# Claude OAuth Credential

## Overview

A value type for the OAuth credential Claude Code keeps for one account: the access token, the refresh token, the two separate expiries, the granted scopes, and the subscription metadata. It is the object Claude Code stores under its credentials entry in the keychain. "The token" is four things, not one, and rotating an account means replacing all of them together, which is why they travel as one value rather than as a string. It lives in the lowest shared tier because every process that touches a login needs it and none owns it: an app has custody (it reads and writes the keychain item), a daemon evaluates it (is the access token still worth sending, and if not, spend the refresh token), and both halves of that conversation cross a process boundary.

## Behavioral Requirements

- **credential-fields**: The credential MUST carry an access token, a refresh token, an optional access-token expiry, an optional refresh-token expiry, a list of scopes, an optional subscription type and an optional rate-limit tier.
- **required-tokens**: The access token and the refresh token MUST be required at construction; every other field MUST be optional with defaults of no expiry, an empty scope list and no subscription or tier.
- **expiry-unit-milliseconds**: The two expiry fields MUST be Unix epoch milliseconds, exactly as Claude Code writes them, and MUST NOT be converted when stored.
- **expiry-seconds-derived**: The credential MUST offer the access expiry and the refresh expiry in epoch seconds, each being the stored milliseconds divided by 1000, and nothing when the stored expiry is absent.
- **value-equality**: Two credentials MUST be equal exactly when all seven fields are equal, so a stored credential can be compared to the live one.
- **codable-wire-form**: The credential MUST encode and decode with field names equal to its property names, because it crosses process boundaries and is read back from the stored item.
- **single-definition**: There MUST be one definition of this credential shape shared by the custody layer and the evaluating layer; neither may declare its own copy.

## Appearance

Not applicable: The credential type is not a visual component.

## States

Not applicable: The credential type is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The credential type presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-o-auth-credential-001 | credential-fields, required-tokens | Construct a credential with only `accessToken: "a"` and `refreshToken: "r"`. | Both expiries are absent, scopes is empty, subscription type and rate-limit tier are absent. |
| claude-o-auth-credential-002 | expiry-unit-milliseconds, expiry-seconds-derived | Construct with `expiresAt: 1750000000000` and read the access expiry in seconds. | `1750000000`; the stored value is still `1750000000000`. |
| claude-o-auth-credential-003 | expiry-seconds-derived | Read the refresh expiry in seconds on a credential whose refresh expiry is absent. | Nothing. |
| claude-o-auth-credential-004 | value-equality | Compare two credentials identical except for the refresh token. | Not equal. |
| claude-o-auth-credential-005 | value-equality | Compare a credential with a copy of itself. | Equal. |
| claude-o-auth-credential-006 | codable-wire-form | Encode a credential with scopes `["user:inference"]`, then decode the result. | The decoded credential equals the original. |
| claude-o-auth-credential-007 | credential-fields | A rotated live credential `a2`/`r2` with `expiresAt: 2000` is compared to a saved credential `a1`/`r1` with `expiresAt: 1000` (as `ClaudeLiveLoginRecordTests` does). | They are not equal, so the saved record is treated as stale. |

## Edge Cases

- **Null / empty input**: An empty scope list is valid and is the default; an empty access or refresh token is accepted without validation, since the type checks nothing about token content.
- **Boundary values**: An expiry of zero converts to zero seconds; a negative expiry converts to a negative number of seconds without clamping. Expiries are floating-point, so a fractional millisecond value divides exactly as given.
- **Concurrent access**: It is a plain value; copies are independent and safe to share across threads.
- **Error states**: Construction cannot fail. Decoding fails when a non-optional field (access token, refresh token or scopes) is missing or mistyped, with the decoder's own error; only the expiries, subscription type and rate-limit tier may be absent from the encoded form.
- **Offline / disconnected state**: Not applicable: The credential type has no network access.
- **Cancellation**: Not applicable: The credential type has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The credential type reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The credential type defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The credential type contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The credential type presents no UI.

## Feature Flags

Not applicable: The credential type contains no feature-flag reference.

## Analytics

Not applicable: The credential type contains no analytics call.

## Privacy

- **Data handled**: Bearer secrets: an access token and a refresh token, plus subscription metadata that identifies the plan.
- **Storage**: The type persists nothing itself; the custody layer stores it in the system keychain.
- **Transmission**: The type transmits nothing itself; it is the payload that crosses a local inter-process boundary between an app and a daemon.
- **Retention**: Held only for the lifetime of the value; callers MUST NOT log it.

## Logging

Not applicable: The credential type calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses the type unchanged from any view model or store. The type is a `struct` conforming to `Codable`, `Sendable` and `Equatable`.
- **Compose**: A Kotlin `data class` with `@Serializable`, `Long?`/`Double?` expiry fields and computed `expirySeconds` properties; data-class equality gives the equality requirement for free.
- **React/Web**: An interface with the seven fields plus pure helper functions `expirySeconds(c)` and `refreshExpirySeconds(c)`; keep expiries as numbers in milliseconds and never store them as `Date`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A `record ClaudeOAuthCredential` in C# with `double?` expiry properties and `ExpirySeconds` computed properties; serialize with System.Text.Json using the same camel-case names. Persist it through `PasswordVault` or Windows Credential Manager under a key from the credential-kind key helper.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/ClaudeAccounts/ClaudeOAuthCredential.swift` |

## Design Decisions

**Decision**: The credential is a struct with public mutable fields rather than an immutable value.
**Rationale**: Rotating an account replaces the tokens and expiries in place, so callers update the fields they received from a refresh; a mutable value type keeps each copy independent. The cost is that nothing enforces that the four parts change together; that discipline stays with the custody layer.
**Approved**: pending

**Decision**: Token contents are not validated or redacted by the type.
**Rationale**: The type is a transport shape. Keeping secrets out of logs is the responsibility of whoever logs; closing this would mean adding a redacting description, which has not been needed because no caller prints the value.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | Reliability |

`separation-of-concerns` passes because the type only describes the credential shape and the milliseconds-to-seconds view; custody (keychain) and evaluation (expiry policy) live in other layers. `unit-test-coverage` is partial: no test file targets `ClaudeOAuthCredential` directly. `AgenticToolkitMacOSTests/ClaudeAccounts/ClaudeLiveLoginRecordTests.swift` builds credentials and compares live to saved ones, so equality is exercised indirectly, but the seconds conversion and the optional-field defaults have no assertion.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
