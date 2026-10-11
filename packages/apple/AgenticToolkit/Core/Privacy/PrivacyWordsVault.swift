import Combine
import Foundation

/// The privacy words while the app is running: nothing until the user
/// authenticates, then the pairs read from the keychain, held in memory and
/// nowhere else.
///
/// One per app, shared by every private terminal, so unlocking one unlocks
/// the words for all of them and an edit applies to all of them at once.
/// Being unlocked is not the same as being *shown*: each private terminal
/// still asks the user to authenticate before it lifts its privacy screen.
@MainActor
public final class PrivacyWordsVault: ObservableObject {

    public let store: PrivacyWordStore

    /// The words as a filter, or nil while they have not been read.
    @Published public private(set) var filter: TextSubstitutionFilter?

    public var isUnlocked: Bool { filter != nil }

    public init(store: PrivacyWordStore) {
        self.store = store
    }

    /// Authenticates the user and, the first time, reads the words. Every call
    /// prompts: this is what stands between the user's screen and someone
    /// else at the keyboard, so success is never remembered.
    public func authenticate(reason: String) async throws {
        let context = try await PrivacyWordStore.authenticate(reason: reason)
        if filter == nil {
            filter = TextSubstitutionFilter(pairs: try store.load(context: context))
        }
    }

    /// Stores `pairs` in the keychain and applies them. Only an unlocked vault
    /// can save — the editor authenticates before it opens.
    public func save(_ pairs: [TextSubstitutionFilter.Pair]) throws {
        precondition(isUnlocked, "The privacy words were saved without being unlocked.")
        let filter = TextSubstitutionFilter(pairs: pairs)
        try store.save(filter.pairs)
        self.filter = filter
    }
}
