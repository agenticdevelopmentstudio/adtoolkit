
- **severity-cases**: `ExtensionMessageSeverity` MUST expose exactly three cases — `information`, `warning`, and `error` — one per `vscode.window.show*Message` call kind.
- **severity-value-semantics**: `ExtensionMessageSeverity` MUST be safe to use across concurrent execution contexts and MUST support equality comparison, and MUST carry no associated value on any case.
- **request-stored-shape**: `ExtensionMessageRequest` MUST carry exactly six immutable stored properties: `severity` (`ExtensionMessageSeverity`), `message` (`String`), `detail` (`String?`), `isModal` (`Bool`), `itemTitles` (`[String]`), and `closeAffordanceIndices` (`[Int]`).
- **request-thread-safe-no-equality**: `ExtensionMessageRequest` MUST be safe to pass across concurrent execution contexts; it MUST NOT support built-in equality comparison — a caller that needs equality must compare individual fields itself.
- **request-module-private-construction**: `ExtensionMessageRequest` MUST only be constructible from within the component's own implementation module; a caller outside that module MUST NOT be able to construct an `ExtensionMessageRequest` value directly.
- **close-affordance-indices-are-a-list**: `closeAffordanceIndices` MUST hold every index into `itemTitles` whose corresponding message item carried a truthy `isCloseAffordance`, in item order, as a list rather than a single optional index, so that more than one flagged item is representable.
- **close-affordance-indices-empty-default**: `closeAffordanceIndices` MUST be empty when no item in `itemTitles` was flagged `isCloseAffordance`.
- **close-affordance-indices-within-item-bounds**: every value in `closeAffordanceIndices` MUST be a valid index into `itemTitles`; `ExtensionMessageRequest` performs no bounds check of its own, so upholding this invariant MUST be the responsibility of whatever constructs the request.
- **presenting-protocol-isolation**: `ExtensionMessagePresenting` MUST serialize a conforming type's stored-property access and the synchronous portion of `presentMessage(_:)` onto a single, consistent execution context.
- **presenting-protocol-class-only**: `ExtensionMessagePresenting` MUST constrain conformers to reference types; a value type MUST NOT conform to it.
- **presenting-single-operation**: `ExtensionMessagePresenting` MUST declare exactly one requirement — `presentMessage(_:)`, taking one `ExtensionMessageRequest` and asynchronously producing an optional integer index — and MUST supply no default implementation for it.
- **present-message-return-index**: when the user chooses an item, `presentMessage(_:)` MUST return the index of that item into `request.itemTitles`.
- **present-message-return-nil-on-dismiss**: `presentMessage(_:)` MUST return `nil` when the user dismissed the message without choosing an item.
- **present-message-empty-items-always-nil**: `presentMessage(_:)` MUST return `nil` whenever `request.itemTitles` is empty, regardless of how the message was dismissed, because there is no item to choose.
- **present-message-no-throwing-path**: `presentMessage(_:)` MUST NOT throw; the protocol defines no error case, so a conformer that cannot present the message at all MUST resolve the call the same way as a user dismissal, `nil`, rather than signal the failure by any other means.
- **is-modal-carried-not-enforced**: `isModal` MUST be carried on `ExtensionMessageRequest` exactly as supplied; `ExtensionMessagePresenting` places no requirement on whether, or how, a conformer's presentation honors it.
- **detail-optional-presentation**: a conformer MAY omit presenting `detail` in its own surface when it is `nil`; the protocol imposes no non-nil or minimum-length constraint on either `message` or `detail`.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

