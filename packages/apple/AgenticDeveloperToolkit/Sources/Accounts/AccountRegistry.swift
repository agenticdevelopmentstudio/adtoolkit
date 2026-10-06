import Foundation

/// The accounts an app offers, in display order. `add`/`remove` exist so the
/// panel's `+`/`−` can be enabled later without touching `Account`.
@MainActor
public final class AccountRegistry {
    public private(set) var accounts: [any Account]
    public var onChange: @MainActor () -> Void = {}

    public init(accounts: [any Account] = []) {
        self.accounts = accounts
    }

    /// Appends `account`. An id already present is ignored (idempotency).
    public func add(_ account: any Account) {
        guard !accounts.contains(where: { $0.id == account.id }) else { return }
        accounts.append(account)
        onChange()
    }

    /// Removes the account with `id`. An unknown id is a no-op.
    public func remove(id: String) {
        guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
        accounts.remove(at: index)
        onChange()
    }
}
