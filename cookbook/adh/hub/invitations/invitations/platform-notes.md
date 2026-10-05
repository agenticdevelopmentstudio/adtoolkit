
- **SwiftUI**: The five Apple files here are model/data/logic types with no
  SwiftUI of their own; a SwiftUI host renders the `HTDVItem`/`FormSpec`
  trees these topics and `AdminNotesRail` produce, exactly as the sibling
  `htdv-engine` and `hub-domain-customers` recipes describe for their own
  topics.
- **Compose**: A Kotlin/Compose port would model `InvitationRequest`,
  `PendingUser`, `Invite`, `AdminNote`, `HistoryEntry`, and the write-side
  `DraftUser`/`AdminNoteInput`/`InvitationSend` as `data class`es, expose
  `InvitationsDataSource` as a `suspend`-fun interface, and drive Compose
  state from a `ViewModel`'s `StateFlow` rather than an `@MainActor` class;
  the notes rewrite-and-replace pattern (per
  **notes-rewrite-is-read-then-overwrite**) ports unchanged as a `suspend`
  function taking an explicit transform lambda.
- **React/Web**: `invitations.ts`/`wire.ts` are already the web
  implementation of the recipient-facing half of this domain; a port of the
  Apple admin-facing half to a web admin console would model
  `InvitationsDataSource` as a set of `fetch`/`authedJson` calls analogous
  to `invitations.ts`'s own shape, and would need to decide, for
  consistency, on one single error-surfacing strategy rather than the three
  different ones `invitations.ts` itself uses today (per the **Error
  states** edge case).
- **AppKit / UIKit**: Neither framework is used by any of the five Apple
  files here; they are UI-framework-agnostic and are consumed the same way
  regardless of whether the host screen is AppKit, UIKit, or SwiftUI, same
  as the sibling `hub-domain-customers` recipe's own topics.
- **WinUI 3**: `InvitationRequest`, `PendingUser`, `Invite`, `DraftUser`,
  `InvitationChannelNote`, `InvitationSend`, `AdminNote`, `AdminNoteInput`,
  and `HistoryEntry` map to plain C# records or classes (no
  `INotifyPropertyChanged` needed, since none of them are bound directly to
  XAML controls); `InvitationsDataSource`'s eleven `async throws` methods map
  to a C# interface of `Task`-returning methods, each caller awaiting and
  catching a typed exception in place of Swift's `throws`/`HubError`. The
  admin-notes read-then-overwrite pattern in
  **notes-rewrite-is-read-then-overwrite** ports directly as a method that
  awaits the current list, applies a `Func<List<AdminNoteInput>,
  List<AdminNoteInput>>` transform, and awaits the replace call — .NET has
  no `nonisolated`/`@Sendable` distinction to preserve, since a plain
  `async` method already carries no actor affinity. For the recipient-facing
  web-equivalent flow, `System.Net.Http.HttpClient` with
  `System.Text.Json` replaces `fetch`/`authedJson`; a WinUI 3 registration
  page collecting `email`/`password`/`name` should route those three fields
  through `PasswordBox`/`Windows.Storage` conventions for the password field
  specifically, never a plain bound string, mirroring the same "never store
  the password" boundary this recipe records in **Privacy**.
- **Swift types (reference implementation)**: `RequestsTopic`, `PendingUsersTopic`, and `InvitesTopic`
  are `@MainActor final class` types and `AdminNotesRail` is a `@MainActor public struct`; none is
  `Sendable`, so the compiler keeps every instance confined to the main actor's isolation domain.
  `InvitationsDataSource` is `AnyObject`-constrained with eleven `async throws` methods, held as a
  `let` reference. `AdminNotesRail.rewrite` is `nonisolated private static`, taking its transform as
  a `@Sendable` closure parameter so `FormAction.perform` (which requires a `@Sendable` closure) can
  call it without making `AdminNotesRail` itself `Sendable`.

