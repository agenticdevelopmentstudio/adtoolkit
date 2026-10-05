
- **SwiftUI**: A `Form` section of four `TextField`s bound to a `@Binding<ContactDetails>`; use `.onSubmit` or focus loss to report.
- **Compose**: A `Column` of four `OutlinedTextField`s with state hoisted to a `ContactDetails` value and an `onChange` lambda.
- **React/Web**: A `<fieldset>` of four labelled `<input>`s (`type=email`, `tel`, `url` where wanted) controlled by one record in state.
- **AppKit / UIKit (source)**: `ComposableSettings.ContactDetails` is a `Codable`, `Equatable`, `Sendable` struct of four strings. `ContactFieldsView` is an `@MainActor` `GroupView` subclass whose four rows are `TextEditView`s bound to a `ViewModel` of getter and setter closures. An `isLoading` flag suppresses reporting while `details` is assigned; `applyToFields` writes straight to the text fields and skips one with a live field editor; `revert(attempted:stored:)` uses `FieldSync.force` for refused fields. It calls the designated `GroupView.init(withHeaderView:)` because a subclass cannot chain to the convenience initializer.
- **WinUI 3**: A `StackPanel` of four `TextBox`es with `Header` set, a `ContactDetails` record updated on `LostFocus`, and an `isLoading` guard around programmatic assignment.

