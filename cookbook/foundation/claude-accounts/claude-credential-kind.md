---
id: D457C4D4-005C-4FCB-A3A6-3E1680BCB561
title: "Claude Credential Kind"
domain: adtoolkit://cookbook/foundation/claude-accounts/claude-credential-kind
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The two kinds of Claude credential an app saves, and the single key spelling that names one kind of credential for one account."
platforms:
  - swift
  - macos
tags:
  - foundation
  - claude-accounts
  - credentials
  - keys
depends-on: []
related:
  - adtoolkit://cookbook/foundation/claude-accounts/claude-o-auth-credential
references: []
approved-by: ""
approved-date: ""
---

# Claude Credential Kind

## Overview

A closed two-case enumeration naming which kind of Claude credential an app has saved and which kind a quota reading measured: a full OAuth login, or a long-lived token minted by the Claude command-line setup-token flow. The two are not halves of one account: they bill against different rate-limit buckets, so one email can read 100% on one and 8% on the other at the same instant, and they expire and revoke independently. The type also owns the one spelling of the key that names "this kind of credential, for this account", because the keychain item a credential is stored under, the per-credential show-in-quota-window preference, and the quota section a daemon ships are written by one layer and read by another and must agree. It sits in the lowest shared tier because every layer names the same fact.

## Behavioral Requirements

- **two-kinds**: The kind set MUST contain exactly two cases: an OAuth login, whose raw value is `oauth`, and a long-lived token, whose raw value is `long-lived`.
- **raw-value-stable**: The raw value of each case MUST be the string above; it is the wire and storage form, so it MUST NOT change between releases.
- **title-per-kind**: Each kind MUST provide a display title for a type column, a details pane and a quota card header: `OAuth` for the OAuth login and `Long-lived` for the long-lived token.
- **key-spelling**: The item key for a credential MUST be the kind raw value, a colon, then the account name (for example `oauth:alice@example.com`). This is the only spelling of the key; no other layer may build it by hand.
- **key-from-raw-value**: Building a key from a raw kind string that is absent or empty MUST return the bare account name unchanged (the legacy key form). A raw kind string this build does not recognize but that is non-empty MUST still produce a distinct `<raw>:<account>` key.
- **parse-inverse**: Parsing an item key MUST split it at the first colon and return the kind and the account name when the text before the colon is a known raw value; otherwise (no colon, or an unknown prefix, including a legacy bare account name) it MUST return nothing.
- **account-names-keep-colons-after-first**: Parsing MUST keep everything after the first colon as the account name, so a name that itself contains a colon is returned intact.
- **codable-and-enumerable**: The kind MUST be encodable and decodable by its raw value and MUST expose every case, so a settings table can list the kinds.

## Appearance

Not applicable: The kind type is not a visual component.

## States

Not applicable: The kind type is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The kind type presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-credential-kind-001 | two-kinds, raw-value-stable | Read the raw values of the OAuth kind and the long-lived kind. | `oauth` and `long-lived`. |
| claude-credential-kind-002 | title-per-kind | Read the title of each kind. | `OAuth` and `Long-lived`. |
| claude-credential-kind-003 | key-spelling | Build the key for account `alice@example.com` under the OAuth kind. | `oauth:alice@example.com`. |
| claude-credential-kind-004 | key-spelling | Build the key for the same account under the long-lived kind. | `long-lived:alice@example.com`, distinct from the OAuth key. |
| claude-credential-kind-005 | key-from-raw-value | Build a key from account `alice@example.com` with raw kind absent, then with raw kind empty. | Both return `alice@example.com`. |
| claude-credential-kind-006 | key-from-raw-value | Build a key from raw kind `future-kind` and account `alice@example.com`. | `future-kind:alice@example.com`. |
| claude-credential-kind-007 | parse-inverse | Parse `oauth:alice@example.com`. | Kind OAuth, name `alice@example.com`. |
| claude-credential-kind-008 | parse-inverse | Parse `alice@example.com` (legacy) and `future-kind:alice@example.com`. | Both return nothing. |
| claude-credential-kind-009 | account-names-keep-colons-after-first | Parse `long-lived:team:alice`. | Kind long-lived, name `team:alice`. |

## Edge Cases

- **Null / empty input**: A missing or empty raw kind yields the legacy bare account key (`key-from-raw-value`); an empty item key parses to nothing.
- **Boundary values**: An item key whose first colon is its first character has an empty prefix that matches no kind and parses to nothing; a key ending in a colon parses to a known kind with an empty name.
- **Concurrent access**: The type holds no state, so any number of callers may build and parse keys at once.
- **Error states**: Parsing never fails with an error; an unrecognized key returns nothing and the caller treats it as a legacy or foreign key.
- **Offline / disconnected state**: Not applicable: The kind type has no network access.
- **Cancellation**: Not applicable: The kind type has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The kind type reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The kind type defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The kind type contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The kind type presents no UI.

## Feature Flags

Not applicable: The kind type contains no feature-flag reference.

## Analytics

Not applicable: The kind type contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The kind type calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses the type unchanged from any view model or store. The type is a `String`-backed enumeration conforming to `Codable`, `Sendable` and `CaseIterable`.
- **Compose**: Model it as an enum class with a `value` string (`oauth`, `long-lived`), a `title`, and companion `key(account, kindValue)` and `parse(itemKey)` functions; serialize by `value`.
- **React/Web**: A string-literal union `'oauth' | 'long-lived'` with a title map and pure `credentialKey` / `parseCredentialKey` functions; split the key at the first colon only.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: An `enum ClaudeCredentialKind` with a `[JsonConverter(typeof(StringEnumConverter))]`-style mapping to `oauth` and `long-lived`, a `Title` extension method, and static `Key` and `Parse` helpers; use `IndexOf(':')` for the first colon so account names keep later colons. Store keys in Windows Credential Manager target names built through that one helper.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/ClaudeAccounts/ClaudeCredentialKind.swift` |

## Design Decisions

**Decision**: The long-lived token and the OAuth login are separate credentials with separate keys, never merged under one account name.
**Rationale**: The type's own documentation records why: merging them produced one row, one usage number and one delete for two things that measure, expire and revoke independently. The key spelling therefore carries the kind so each credential keeps its own item, preference and quota card.
**Approved**: pending

**Decision**: An unrecognized raw kind still produces a distinct key rather than collapsing to the bare account name.
**Rationale**: The wire form may carry a kind this build has never heard of; that credential is still distinct and has to get a distinct key, so only a missing or empty kind falls back to the legacy form.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`separation-of-concerns` passes because the type does exactly one thing, naming the credential kinds and their one key spelling, and holds no storage, network or UI of its own. `unit-test-coverage` is partial: no test file targets `ClaudeCredentialKind` directly; `AgenticToolkitMacOSTests/ClaudeAccounts/ClaudeLiveLoginRecordTests.swift` constructs accounts with each kind but does not assert the key or parse functions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
