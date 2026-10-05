
- **SwiftUI**: Compose a `Form`/`VStack` with an optional
  `Text(title).font(.headline)`, an optional
  `Text(prompt).font(.caption).foregroundStyle(.secondary)`, a
  `SecureField`/`TextField` bound to `@State` and driving validation from
  `.onChange(of:)`, and an optional `Text(validationMessage)` styled per
  severity (`.foregroundStyle(.red)`/`.orange`/`.secondary`), shown only
  when a message is present — mirroring `validation-message-shown`/
  `validation-message-hidden`. `.onSubmit` alone only gates a Return
  against the current `canAccept` value; it cannot replay one pressed
  while validation is in flight. Mirror `model-gated-acceptance`/
  `acceptance-deferral` with a `@State pendingSubmit` flag: `.onSubmit`
  accepts immediately when the SwiftUI-side `canAccept` is already true,
  otherwise (while validating) sets `pendingSubmit = true` and does not
  accept; an `.onChange(of: canAccept)` (or the validation-result
  callback) checks `pendingSubmit` when `canAccept` turns true, accepts,
  and clears the flag — the same held-then-replayed Return the AppKit
  source implements, not a drop. Cancel via a
  `.keyboardShortcut(.cancelAction)` button, mirroring
  `escape-cancellation`.
- **Compose**: Use a `Column` with an optional title `Text` (`titleMedium`),
  an optional prompt `Text` (`bodySmall`, `onSurfaceVariant`), an
  `OutlinedTextField` (with `visualTransformation = PasswordVisualTransformation()`
  when secure) driving validation from `onValueChange`, and a `Text`
  colored by `MaterialTheme.colorScheme.error`/tertiary/`onSurfaceVariant`
  for the validation message, shown only when non-null. Gate the IME
  "Done" action and a confirm button the same way `model.canAccept` gates
  Return here, and map system back-press to cancellation, mirroring
  `escape-cancellation`.
- **React/Web**: A `<form>` with an optional `<h2>`/`<p>` for title/prompt,
  an `<input type={isPassword ? "password" : "text"}>` wired to `onChange`
  for per-keystroke validation, and a `role="alert"` `<span>` for the
  validation message (colored by severity), rendered only when a message
  exists — mirroring the show/hide and severity-color requirements. Gate
  the form's `onSubmit` on the same "not currently validating and no
  active error" condition `model.canAccept` expresses, and bind an Escape
  `keydown` handler (or a Cancel button) to cancellation, mirroring
  `escape-cancellation`.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/Features/Extensions/UI/ExtensionInputBoxViewController.swift`
  — macOS-only (`import AppKit`), `@MainActor` `NSViewController`, laid
  out entirely with programmatic Auto Layout (no XIB/Storyboard), sharing
  `PickerKeyboardController` with `ExtensionQuickPickViewController`.
  The pending-Return and once-per-instance-prefill guards described by
  `acceptance-deferral`/`pending-acceptance-reset` and
  `prefill-validation-once` are backed by two private properties,
  `acceptWhenValidationLands` and `hasValidatedPrefill`.
  `focusField()` makes the field the window's first responder, then sets
  the field editor's `selectedRange` to `model.initialSelectionUTF16Range()`
  — the order matters because setting the range before the field has a
  field editor has no effect. `escape-cancellation` is backed by a
  window-level `NSEvent` monitor started in `viewDidAppear` and stopped in
  `viewWillDisappear`, so it exists only while the panel is actually on
  screen. There is no UIKit code path in source; a UIKit port would
  replace `NSSecureTextField`/`NSTextField` with `UITextField`
  (`isSecureTextEntry`), `NSTextFieldDelegate` with
  `UITextFieldDelegate`'s `textField(_:shouldChangeCharactersIn:
  replacementString:)`/`textFieldDidEndEditing`, and the window-level
  Escape `NSEvent` monitor with a Cancel bar item or interactive dismissal
  (iOS has no Escape-key equivalent).
- **WinUI 3** (the reason this recipe exists): Build the panel as a
  `StackPanel` inside the picker's shared content host: an optional
  `TextBlock` (`Style="{StaticResource BodyStrongTextBlockStyle}"`) for
  the title, an optional `TextBlock`
  (`Style="{StaticResource CaptionTextBlockStyle}"`, `Opacity="0.7"`) for
  the prompt, a `PasswordBox` when the request is a password field or a
  `TextBox` otherwise (`Text="{x:Bind Value, Mode=TwoWay}"`), and a
  `TextBlock` for the validation message whose `Visibility` is bound to
  "message present" and whose `Foreground` switches between the theme's
  error/caution/tertiary brushes for `.error`/`.warning`/`.information` —
  mirroring `validation-message-shown`/`validation-message-hidden`.
  Wire the `TextBox`/`PasswordBox`'s `TextChanged`/`PasswordChanged` event
  to the same commit-and-revalidate round trip
  `value-commit-and-revalidation` describes; gate the panel's default
  action — a `ContentDialog.DefaultButton` set to `Primary` when the panel
  is hosted as a `ContentDialog`, or a `KeyboardAccelerator` for
  `VirtualKey.Enter` on the root otherwise — on the WinUI equivalent of
  `model.canAccept`, mirroring `model-gated-acceptance` and
  `acceptance-deferral`; and drive Cancel from
  `ContentDialog.CloseButton` (or a `KeyboardAccelerator` for
  `VirtualKey.Escape`) so it fires unconditional cancellation, mirroring
  `escape-cancellation` — WinUI 3 has no `IsDefault`/`IsCancel` button
  properties (those are WPF's). Map focus to
  `TextBox`/`PasswordBox.Focus(FocusState.Programmatic)`; initial
  selection via `Select(start, length)` applies only to `TextBox` —
  `PasswordBox` exposes no selection API, so a secure field can only be
  focused, not pre-selected, which is as far as
  `focus-then-initial-selection`'s focus-then-select order can carry over
  for a password field.

