---
id: 5CACE721-E5EB-4D7A-AD2B-3EB67775CB88
title: "Symbol Image"
domain: adtoolkit://cookbook/ui/ns-image-symbol
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A system symbol lookup that never fails — a missing symbol name yields a blank template image of symbol size that keeps its accessibility description."
platforms:
  - swift
  - macos
tags:
  - ui
  - icons
  - symbols
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Symbol Image

## Overview

The symbol image is a lookup that turns a system symbol name into an image
and never answers "nothing". A system symbol lookup fails for a misspelled
name or for a symbol the running operating system version does not ship, and
a caller that force-unwraps that failure crashes whatever view happened to
build the control. This component answers a blank template image of symbol
size instead, so the control still lays out and still carries its
accessibility description.

## Behavioral Requirements

- **returns-system-symbol-when-available**: When the system provides a
  symbol with the given name, the lookup MUST return that system image with
  the given accessibility description applied.
- **never-returns-nothing**: The lookup MUST always return an image; it MUST
  NOT fail, trap or return an absent value for any name, including an empty
  or misspelled one.
- **blank-fallback-is-symbol-sized**: When the system provides no symbol with
  the given name, the returned image MUST be a blank image of 16 by 16 points.
- **blank-fallback-is-template**: When the system provides no symbol with the
  given name, the returned image MUST be marked as a template image so the
  control that shows it tints it like a real symbol.
- **blank-fallback-keeps-description**: When the system provides no symbol
  with the given name, the returned image MUST carry the accessibility
  description that was passed in, so assistive technology still names the
  control.
- **description-is-optional**: The accessibility description MAY be absent;
  an absent description MUST be carried through unchanged on both the system
  image and the fallback image.
- **no-diagnostic-on-fallback**: The lookup MUST NOT log, throw or otherwise
  signal that a fallback was used; a missing symbol is visible only as a
  blank image.

## Appearance

- **Corner radius**: Not applicable — the component returns an image, not a view.
- **Padding**: Not applicable — the image has no padding of its own.
- **Font**: Not applicable — a system symbol's weight and point size come from
  the control that displays it, not from this lookup.
- **Background**: None; the fallback image is fully transparent.
- **Foreground/Text**: The fallback is a template image, so the displaying
  control's tint colors it; being blank, it draws nothing.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: The fallback image is exactly 16 by 16 points; a system
  symbol image has the size the system gives it.

## States

| State | Appearance change |
|-------|------------------|
| Default | The system symbol image, when the name is known to the running system. |
| Pressed | Not applicable: the component returns an inert image and handles no interaction. |
| Disabled | Not applicable: the image has no enabled concept; the displaying control dims it. |
| Focused | Not applicable: an image never takes focus. |
| Loading | Not applicable: the lookup is synchronous and has no loading state. |

## Accessibility

- **Role/trait**: Not applicable — the image carries no role; the control that
  displays it supplies one.
- **Label requirements**: The accessibility description passed in MUST be
  attached to the returned image, whether it is the system image or the
  blank fallback (see **blank-fallback-keeps-description**).
- **Announce state changes**: Not applicable — the image has no state that changes.
- **Minimum tap target**: Not applicable — the image is not interactive; the
  control that shows it owns its hit area.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ns-image-symbol-001 | returns-system-symbol-when-available | Name `plus`, description `Add` | A system image with non-zero width whose accessibility description is `Add` |
| ns-image-symbol-002 | never-returns-nothing | Name `no.such.symbol.anywhere`, description `Stop` | An image is returned; nothing traps or is absent |
| ns-image-symbol-003 | blank-fallback-is-symbol-sized | Name `no.such.symbol.anywhere`, description `Stop` | The image size equals 16 by 16 points |
| ns-image-symbol-004 | blank-fallback-is-template | Name `no.such.symbol.anywhere`, description `Stop` | The image is marked as a template image |
| ns-image-symbol-005 | blank-fallback-keeps-description | Name `no.such.symbol.anywhere`, description `Stop` | The image's accessibility description equals `Stop` |
| ns-image-symbol-006 | description-is-optional | Name `no.such.symbol.anywhere`, no description | A blank 16 by 16 template image with no accessibility description |

## Edge Cases

- **Null/empty input**: An empty name is not a system symbol and takes the
  fallback path; an absent description is carried through as absent.
- **Boundary values**: The fallback size is fixed at 16 by 16 points
  regardless of the size the caller wanted; the displaying control's symbol
  configuration does not resize a blank image to match a real symbol's
  intrinsic size.
- **Concurrent access**: Not applicable — the lookup holds no state; it
  creates a new image on every call.
- **Error states**: A missing symbol is the one failure the lookup handles,
  and it handles it by returning the blank fallback rather than reporting an
  error.
- **Offline/disconnected state**: Not applicable — the lookup uses only
  symbols installed with the operating system.
- **Silent fallback**: A misspelled symbol name produces a blank control with
  no diagnostic, so a typo is visible only by inspection (see Design Decisions).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| name | text | none (required) | The system symbol name to look up |
| accessibility description | optional text | none (required argument, may be absent) | The description attached to the returned image |

## Deep Linking

Not applicable: the component is a lookup function with no navigable identity.

## Localization

Not applicable: the component renders no text and defines no string keys; the
accessibility description it attaches is supplied, already localized, by the caller.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component performs no animation. |
| Increase Contrast | Not applicable: the image is tinted by the displaying control, which owns contrast handling. |
| Differentiate Without Color | Not applicable: the component conveys nothing through color. |

## Feature Flags

Not applicable: the lookup is unconditional.

## Analytics

Not applicable: the component emits no analytics.

## Privacy

- **Data collected**: None.
- **Storage**: Not applicable — nothing is persisted.
- **Transmission**: Not applicable — nothing leaves the process.
- **Retention**: Not applicable — the returned image belongs to the caller.

## Logging

Not applicable: the component performs no logging; a fallback is deliberately silent.

## Platform Notes

- **SwiftUI**: `Image(systemName:)` already renders an empty space for an unknown name and never fails, so the wrapper is unnecessary there; to carry a description, apply `.accessibilityLabel` to the image.
- **Compose**: Icon lookups through `Icons` are compile-time references and cannot be misspelled; for a name resolved at runtime, wrap the lookup in a function that returns an empty `Spacer` or `Icon` of 16.dp with the same `contentDescription` when the resource is missing.
- **React/Web**: Resolve an icon name through a map and render a `span` of 16px by 16px with the same `aria-label` when the name is not in the map, so a missing icon still lays out and still has a name.
- **AppKit / UIKit**: In `NSImage+Symbol.swift`, `symbol(named:accessibilityDescription:)` is a public static extension method on `NSImage` that calls the system symbol initializer and, when it answers nil, builds `NSImage(size:)` of 16 by 16 with `isTemplate = true` and the description. A UIKit port would use `UIImage(systemName:)` and fall back to a `UIGraphicsImageRenderer` image of 16 by 16 points with `withRenderingMode(.alwaysTemplate)`; `UIImage` has no accessibility description property, so the description is applied to the `UIImageView` or button instead.
- **WinUI 3**: Use a `FontIcon` or `SymbolIcon` whose glyph or `Symbol` value comes from a lookup table of known glyphs; when a name is not in the table, return a `FontIcon` with an empty `Glyph` and `FontSize="16"` inside a 16 by 16 `Viewbox`, and set `AutomationProperties.Name` to the description on the hosting control so the control still lays out and is still named. Template-style tinting comes from `Foreground` bound to the hosting control's theme brush, which an empty glyph simply never draws.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/CoreUI/NSImage+Symbol.swift` |

## Design Decisions

**Decision**: A missing symbol yields a blank 16 by 16 template image instead of an absent value, a trap or a visible placeholder glyph.
**Rationale**: The source's own comment explains that `NSImage(systemSymbolName:)` answers nil for a misspelled name or a symbol this macOS does not ship, and a force-unwrap turns that into a crash in whatever view built the button; a blank image lets the control lay out and keep its description.
**Approved**: pending

**Decision**: The fallback is silent — no log line, assertion or diagnostic marks that a symbol was missing.
**Rationale**: The source returns the blank image without any signal, so a typo in a symbol name shows up only as an empty control; adding a debug-build diagnostic would close that gap but is not in the source today.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |

Separation-of-concerns is passed: the extension has one job, converting a name to an image that always exists, and holds no state or view code. Unit-test-coverage is passed: `NSImageSymbolTests.swift` in `AgenticToolkitCoreUITests` has two tests, one for a known symbol keeping its description and one for an unknown symbol yielding a 16 by 16 template image that keeps its description. Explicit-error-handling is partial because the one failure path is handled deliberately but silently, with no diagnostic (see Design Decisions). Fault-tolerance is passed because no input name, including an empty or misspelled one, can crash the lookup.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
