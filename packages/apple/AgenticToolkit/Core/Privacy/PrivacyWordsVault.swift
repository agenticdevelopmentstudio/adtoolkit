import Combine
import Foundation

/// The privacy words while the app is running: read from the keychain when a
/// private terminal first needs them, held in memory and nowhere else.
///
/// One per app, shared by every private terminal, so an edit applies to all
/// of them at once. Reading the words to run a terminal never prompts;
/// *seeing* them does. Showing a terminal, opening the editor and saving each
/// go through ``authenticate(reason:)``.
@MainActor
public final class PrivacyWordsVault: ObservableObject {

    public let store: PrivacyWordStore

    /// The words as a filter, or nil while they have not been read.
    @Published public private(set) var filter: TextSubstitutionFilter?

    public var isLoaded: Bool { filter != nil }

    public init(store: PrivacyWordStore) {
        self.store = store
    }

    /// Reads the words without prompting, if they are not in memory yet.
    /// Returns whether they are now — false only for words still saved under
    /// the old `userPresence` guard, which wait for ``authenticate(reason:)``.
    @discardableResult
    public func load() throws -> Bool {
        if isLoaded { return true }
        do {
            filter = TextSubstitutionFilter(pairs: try store.load())
            return true
        } catch PrivacyWordStore.StoreError.needsAuthentication {
            return false
        }
    }

    /// Authenticates the user — every call prompts: this is what stands
    /// between the words and someone else at the keyboard, so success is never
    /// remembered — and makes sure the words are in memory. Words still under
    /// the old guard are read with that authentication and saved again
    /// without it, so they never need it to be read again.
    public func authenticate(reason: String) async throws {
        let context = try await PrivacyWordStore.authenticate(reason: reason)
        guard !(try load()) else { return }
        let pairs = try store.load(context: context)
        try store.save(pairs)
        filter = TextSubstitutionFilter(pairs: pairs)
    }

    /// Authenticates the user, then stores `pairs` in the keychain and applies
    /// them.
    public func save(_ pairs: [TextSubstitutionFilter.Pair], reason: String) async throws {
        try await authenticate(reason: reason)
        let filter = TextSubstitutionFilter(pairs: pairs)
        try store.save(filter.pairs)
        self.filter = filter
    }
}
