
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a generic `struct` with `private(set)` state and `mutating` operations, so a view model holds it as a stored property.
- **Compose**: A small class or data class in a view model with `isEditing` and `pending` state; with Compose lists, hold the reload in a `MutableState` and apply it on edit completion.
- **React/Web**: A closure-free class with the four methods; in React, keep it in a ref so a render during editing does not discard the parked value.
- **AppKit / UIKit**: Identical in contract to the SwiftUI note; the AppKit use is a table view whose cell field editor is active when a reload arrives, so the table owner calls begin on edit start and end on `controlTextDidEndEditing`.
- **WinUI 3**: A `struct EditDeferredValue<T>` held by the view model of a `DataGrid` or `ListView` with in-place editing: call `Begin` from `BeginningEdit`, `Offer` from the data-refresh handler, and apply the result of `End` from `CellEditEnded`.

