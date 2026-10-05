
- **placeholder-shown-on-load**: The component MUST show a new placeholder, built from its `contributedView` and `extensionDisplayName`, as its initial on-screen content, before the `resolve` closure is ever called.
- **resolve-called-once-on-first-display**: The component MUST call the `resolve` closure supplied at construction exactly once, on first display, passing `contributedView` and a completion closure.
- **panel-adopted-when-resolved**: The component MUST replace the on-screen placeholder with the panel that `resolve` returned once the completion closure passed to `resolve` has been called, whether that call happens synchronously (before `resolve` returns) or later.
- **no-adoption-without-completion**: The component MUST NOT swap the on-screen placeholder for the panel `resolve` returned until that panel's completion closure has been called; a panel `resolve` returns never appears on screen if its completion closure is never invoked.
- **panel-swap-is-idempotent**: The component MUST NOT re-show the panel if it is already the on-screen content.
- **remains-on-placeholder-when-unresolved**: The component MUST remain on the placeholder indefinitely when `resolve` returns nothing, or when its completion closure is never called; it does not retry and does not time out.
- **panel-removal-reverts-to-placeholder**: The component MUST show a newly built placeholder, replacing the current content, when the adopted panel's `onRemovalRequested` fires, provided the component is not being discarded and a panel is the content currently on screen.
- **no-revert-once-discarding**: The component MUST NOT rebuild a placeholder in response to `onRemovalRequested` once `paneContentWillBeDiscarded()` has run on it.
- **teardown-forwarded-to-panel**: `paneContentWillBeDiscarded()` MUST forward to the held `panel` reference, not to the on-screen `content`, whether or not the panel is currently displayed.
- **teardown-sets-discard-flag-first**: `paneContentWillBeDiscarded()` MUST set its internal discard flag before forwarding to the panel, so that a removal request the panel raises synchronously during its own disposal does not rebuild a placeholder.
- **outgoing-title-callback-cleared**: `show(_:)` MUST clear the outgoing child's `onPaneTitleChange` callback, when the outgoing child conforms to `PaneTitleProviding`, before removing that child from the view hierarchy.
- **incoming-title-callback-installed**: `show(_:)` MUST install a forwarding closure onto the incoming child's `onPaneTitleChange`, when the incoming child conforms to `PaneTitleProviding`, that calls the component's own `onPaneTitleChange`.
- **title-change-notified-on-swap**: `show(_:)` MUST invoke the component's own `onPaneTitleChange` callback once, after installing the incoming child, every time the content is swapped.
- **pane-title-delegates-to-content**: `paneTitle` MUST return the on-screen content's `paneTitle` when that content conforms to `PaneTitleProviding`, and MUST otherwise return `contributedView.name`.
- **child-view-fills-container**: `show(_:)` MUST constrain the incoming child's view to the container's leading, trailing, top, and bottom edges, with no offset.
- **background-tracks-theme-surface**: The container view MUST set its layer's background color from the active theme's `.surface` role immediately on load, and MUST update that color on every subsequent theme change.
- **explicit-construction-only**: The component MUST NOT be constructable without its `contributedView`, `extensionDisplayName`, and `resolve` dependencies explicitly supplied at construction; a serialized-construction path MUST NOT produce a usable instance.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

