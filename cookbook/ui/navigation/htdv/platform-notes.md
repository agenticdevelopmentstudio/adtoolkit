
- **SwiftUI**: A SwiftUI host would wrap `HTDVController` and `FormState`
  in `@Observable` (or bridge their existing `onChange` callback into
  `@Published` properties on an `ObservableObject`) rather than reuse them
  unchanged, since both types are hand-rolled `@MainActor` classes with a
  single-slot callback, not `Observable`/`ObservableObject` themselves.
  Replace `HTDVLayoutEngine`'s manual width tracking with a
  `NavigationSplitView`/`HStack` chosen by a `GeometryReader`-measured
  width and the environment's `horizontalSizeClass`, but keep
  `HTDVLayoutEngine.layout(...)` itself as the pure decision function
  driving that choice. Model each `FormField` case as a `Form` row
  (`TextField`, `Toggle`, `Picker`, `TextField(value:)` with a
  `Formatter`, `DatePicker`, a custom chip-entry view for `.stringSet`)
  bound to `FormState.value(for:)`/`set(_:for:)`.
- **Compose**: Model `HTDVController` as a `ViewModel` exposing
  `StateFlow<HTDVUiState>` (levels/selection/detail/loading/error
  collapsed into one data class) instead of a single-slot callback, and
  `FormState` similarly as a `ViewModel` with `mutableStateOf`/`StateFlow`
  per field. Use Material 3 adaptive's `ListDetailPaneScaffold` (or a
  custom `BoxWithConstraints`-driven row of `LazyColumn`s) in place of
  `HTDVLayoutEngine`'s manual rail-count arithmetic, again keeping an
  equivalent pure `layout(...)` function as the actual decision. Map
  field kinds to `OutlinedTextField`, `Switch`, `ExposedDropdownMenuBox`,
  `OutlinedTextField` with a numeric `KeyboardType` and
  `visualTransformation`, and a `DatePickerDialog`.
- **React/Web**: Model `HTDVController` as a custom hook (e.g.
  `useHtdvController(dataSource)`) built on `useReducer`, with the
  request counter held in a `useRef` so a stale async response can still
  be detected and ignored after a state update triggers a re-render;
  model `FormState` as `useReducer`-driven `values`/`baseline`/`errors`
  state with a `validate` function that mirrors `FormValidator`
  field-by-field (including anchoring a user regex with
  `` `^(?:${pattern})$` `` before calling `.test()`, and wrapping
  `JSON.parse` in a `try`/`catch` for the `.json` field kind). Use a
  `ResizeObserver`-driven width plus a media-query-style compact
  breakpoint in place of `isCompact`, feeding the same rails-vs-stack
  decision.
- **AppKit / UIKit** (source platform): This is the source:
  `Controller/HTDVController.swift`, `Model/HTDVModel.swift`,
  `Model/HTDVCellContent.swift`, `Layout/HTDVLayoutEngine.swift`,
  `Forms/FormSpec.swift`, `Forms/FormValue.swift`, `Forms/FormState.swift`,
  `Forms/FormValidator.swift`, and `Markdown/MarkdownEditing.swift`. The
  engine types themselves (`HTDVController`, `HTDVLayoutEngine`,
  `FormState`, `FormValidator`, `FormSpec`, `FormValue`) import only
  `Foundation` and hold no AppKit/UIKit dependency beyond the
  `PlatformViewController` type alias used as an opaque return/parameter
  type; `MarkdownEditing.swift` is the one file among the nine that also
  ships concrete AppKit (`NSTextView`/`NSViewController`) and UIKit
  (`UITextView`/`UIViewController`) implementations side by side behind
  `#if canImport(AppKit) && !targetEnvironment(macCatalyst)` /
  `#elseif canImport(UIKit)`, selected once at compile time per platform.
  `HTDVController` and `FormState` are each declared `@MainActor` with no
  `Sendable` conformance of their own, confining every mutable property
  and method to the main actor's isolation domain and requiring a caller
  on a different isolation domain to `await` a hop onto it (formerly the
  normative requirements `main-actor-confinement` and
  `form-state-main-actor-confinement`; this is the source of the
  Concurrent Access edge case above). `PlatformViewController` resolves to
  `NSViewController` when AppKit is importable and the build is not Mac
  Catalyst, and to `UIViewController` when UIKit is importable, so every
  closure that vends or receives a view controller (`HTDVDetail.make`,
  `HTDVCreateAction.perform`, the markdown editing contract's factories)
  is typed identically on both platforms (formerly the normative
  requirement `platform-view-controller-alias`). `PlainTextEditorViewController`
  forwards live edits through `NSTextViewDelegate.textDidChange(_:)`
  (reading the text view's `string`) on AppKit and
  `UITextViewDelegate.textViewDidChange(_:)` (reading the text view's
  `text`, falling back to `""` when `nil`) on UIKit, and disables
  automatic quote/dash substitution via
  `isAutomaticQuoteSubstitutionEnabled`/`isAutomaticDashSubstitutionEnabled`
  on AppKit and `smartQuotesType`/`smartDashesType` (plus
  `autocorrectionType`/`autocapitalizationType`) on UIKit.
  `FormValidator`'s bound-formatting helper builds a fresh
  `NumberFormatter` per call rather than a cached `static let`, since
  `NumberFormatter` is not `Sendable`, and formats via
  `NumberFormatter`/`NSNumber` rather than `Int(_:)` so an out-of-`Int`-
  range bound cannot trap - see Design Decisions.
- **WinUI 3**: Model `HTDVController` as a plain C# class (or a
  `CommunityToolkit.Mvvm` `ObservableObject`) exposing
  `ObservableCollection<HTDVLevel>`-style properties and raising
  `INotifyPropertyChanged`/a C# `event` in place of the single-slot
  `onChange` closure; keep the request-counter-based stale-response guard
  using a plain `int` field checked after each `await`ed
  `Task<HTDVLevel>`/`Task<HTDVChild>` completes (a `CancellationToken` is
  a valid alternative for the *deeper* in-flight load `popToLevel`/
  `clearDetail` want to discard, but the source's own approach is
  result-discarding, not task-cancelling - see Design Decisions). Use a
  `NavigationView` in "left compact" mode, or a hand-built
  `Grid`/`AdaptiveTrigger`+`VisualStateManager` pair, to switch between
  side-by-side rail columns and a single-pane stack, mirroring
  `HTDVLayoutEngine.Mode`. Model `FormField` as an `abstract record`
  hierarchy (`TextField`, `ToggleField`, `SelectField`, `NumberField`,
  `DateField`, `StringSetField`, `ReadOnlyField`, `MarkdownField`,
  `JsonField`) and bind to `TextBox`, `ToggleSwitch`, `ComboBox`,
  `NumberBox`, `CalendarDatePicker`, and a `TokenizingTextBox`-style
  control for the string-set kind; validate with
  `System.Text.RegularExpressions.Regex`, anchoring a supplied pattern
  with `^(?:...)$` exactly as `FormValidator` does, and use
  `double.ToString("G", CultureInfo)`-based formatting (not
  `int.Parse`) for bounds messages so an out-of-`int`-range `maximum`
  cannot throw while building the message. `HTDVDataSource`'s
  network-backed implementations would use `HttpClient` and
  `System.Text.Json`; nothing in these nine sources needs
  `Windows.Storage`, since none of them persists anything (see Privacy).

