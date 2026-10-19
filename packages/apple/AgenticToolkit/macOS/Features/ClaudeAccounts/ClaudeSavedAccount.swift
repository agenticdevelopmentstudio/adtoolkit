import AgenticToolkitCore
import Foundation
import os
import Security

/// One credential the app has saved, as it is stored in the Keychain.
///
/// One keychain item per credential, named `"<kind>:<account>"`, holding this as
/// JSON. One-per-item rather than one big store item is what lets the two
/// locations hold different sets without merging logic: a setup token in iCloud
/// Keychain is simply an item a second Mac picks up, without either side ever
/// writing the other's item, while each Mac's logins stay its own.
///
/// A record holds **exactly one** credential, the one its `kind` names. An email
/// with both a login and a setup token is two records, listed separately,
/// measured separately and deleted separately — see `ClaudeCredentialKind`.
public struct ClaudeSavedAccount: Codable, Sendable, Equatable {

    /// The account name, which is the email the account reports.
    public var name: String
    /// Which credential this record holds. Authoritative: it decides which of
    /// the two fields below is meaningful, and which keychain item the record
    /// lives in.
    public var kind: ClaudeCredentialKind
    /// Epoch seconds, set when the app first saved it.
    public var addedAt: Double
    /// The login's own identity label. Empty for a token typed in by hand,
    /// where nothing but the name is known.
    public var identity: String
    public var accountUUID: String
    /// Set only on a `.oauth` record.
    public var oauth: ClaudeOAuthCredential?
    /// Set only on a `.longLived` record.
    public var longLivedToken: String?
    /// `~/.claude.json`'s `oauthAccount` block as it stood when this login was
    /// captured, serialized. Restored verbatim on a switch, so the rotated
    /// account arrives with its own organization, plan and seat rather than the
    /// previous account's.
    public var configAccount: String?

    public init(
        name: String, kind: ClaudeCredentialKind,
        addedAt: Double = Date().timeIntervalSince1970,
        identity: String = "", accountUUID: String = "",
        oauth: ClaudeOAuthCredential? = nil, longLivedToken: String? = nil,
        configAccount: String? = nil
    ) {
        self.name = name
        self.kind = kind
        self.addedAt = addedAt
        self.identity = identity
        self.accountUUID = accountUUID
        self.oauth = oauth
        self.longLivedToken = longLivedToken
        self.configAccount = configAccount
    }

    /// The keychain item this record lives in.
    public var itemKey: String { kind.key(for: name) }

    /// The secret the eye and copy buttons reveal — this record's own, never the
    /// other kind's.
    public var revealableToken: String? {
        switch kind {
        case .oauth: return oauth?.accessToken
        case .longLived: return longLivedToken
        }
    }

    /// Turns one stored keychain item into the record or records it represents.
    ///
    /// Items written before the split can hold both credentials in one record,
    /// because the store used to merge them under one name. One such item means
    /// two records, and a `Decodable` initializer cannot return two values — so
    /// the split lives here, one level above `Codable`, and every reader goes
    /// through it instead of decoding directly.
    public static func split(storedItem data: Data) -> [ClaudeSavedAccount] {
        guard let stored = try? JSONDecoder().decode(ClaudeSavedAccount.self, from: data)
        else { return [] }
        guard stored.oauth != nil, stored.longLivedToken?.isEmpty == false else {
            return [stored.holdingOnlyItsOwnCredential()]
        }
        var login = stored
        login.kind = .oauth
        var token = stored
        token.kind = .longLived
        return [login.holdingOnlyItsOwnCredential(), token.holdingOnlyItsOwnCredential()]
    }

    /// The record with the credential its kind does not name cleared, so a
    /// record's kind and its payload can never disagree.
    private func holdingOnlyItsOwnCredential() -> ClaudeSavedAccount {
        var copy = self
        switch kind {
        case .oauth: copy.longLivedToken = nil
        case .longLived: copy.oauth = nil
        }
        return copy
    }

    private enum CodingKeys: String, CodingKey {
        case name, kind, addedAt, identity, accountUUID, oauth, longLivedToken, configAccount
    }

    /// Hand-written for one reason: `kind` did not exist when the first items
    /// were saved, and an item without it still has to decode. Which credential
    /// the record carries is what it always was, so that is what it decodes as.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        addedAt = try container.decodeIfPresent(Double.self, forKey: .addedAt)
            ?? Date().timeIntervalSince1970
        identity = try container.decodeIfPresent(String.self, forKey: .identity) ?? ""
        accountUUID = try container.decodeIfPresent(String.self, forKey: .accountUUID) ?? ""
        oauth = try container.decodeIfPresent(ClaudeOAuthCredential.self, forKey: .oauth)
        longLivedToken = try container.decodeIfPresent(String.self, forKey: .longLivedToken)
        configAccount = try container.decodeIfPresent(String.self, forKey: .configAccount)
        let stored = try container.decodeIfPresent(ClaudeCredentialKind.self, forKey: .kind)
        kind = stored ?? (longLivedToken?.isEmpty == false ? .longLived : .oauth)
    }
}

/// The app's own credential store, kept in the Keychain.
///
/// **Where a credential lives is decided by its kind** (`ClaudeKeychainLocation
/// .home(of:)`): logins in this Mac's login keychain, setup tokens in iCloud
/// Keychain. Reads span both, because records saved before that rule may still
/// be in the other one; `all()` moves them, and every record remembers where it
/// actually lives.
public enum ClaudeAccountKeychainStore {

    /// One saved credential, which keychain it came out of, and the item it was
    /// read from.
    ///
    /// `itemKey` is carried rather than re-derived because it is the record's
    /// address: normally `account.itemKey`, but a legacy item whose migration
    /// could not be written is still addressed by its bare account name, and a
    /// delete aimed at the derived key would miss it.
    public struct Located: Sendable {
        public let account: ClaudeSavedAccount
        public let location: ClaudeKeychainLocation
        public let itemKey: String
    }

    /// One legacy item, as read, plus the records hiding inside it.
    private struct LegacyItem {
        let itemKey: String
        let location: ClaudeKeychainLocation
        let records: [ClaudeSavedAccount]
    }

    /// Every credential this app has saved, from both keychains.
    ///
    /// A location this build can't reach contributes nothing rather than
    /// failing the read: on a the app signed without the Keychain Sharing
    /// entitlement, `.shared` is simply not there, and a listing that threw
    /// would hide the local accounts too.
    ///
    /// Legacy bare-name items are migrated here, as a side effect of reading
    /// them, and so are records in the wrong keychain for their kind
    /// (`Placement`). That is deliberate: with one migration site, every other
    /// verb in this store deals only with kind-keyed items in their kind's
    /// keychain, instead of each one growing a legacy branch of its own.
    public static func all() async throws -> [Located] {
        let unmoved = await ClaudeKeychain.moveLoginItemsToDataProtection(
            service: ClaudeKeychain.savedAccountsService)
        if !unmoved.isEmpty {
            logger.error(
                "Left \(unmoved.count, privacy: .public) saved login(s) in the login keychain: they could not be moved")
        }
        var found: [Located] = []
        var legacy: [LegacyItem] = []
        var firstFailure: Error?
        var sharedReachable = true
        for location in ClaudeKeychainLocation.allCases {
            do {
                let rows = try await ClaudeKeychain.readAll(
                    service: ClaudeKeychain.savedAccountsService, location: location)
                for row in rows {
                    let records = ClaudeSavedAccount.split(storedItem: row.data)
                    guard ClaudeCredentialKind.parse(itemKey: row.account) != nil else {
                        legacy.append(LegacyItem(
                            itemKey: row.account, location: location, records: records))
                        continue
                    }
                    found += records.map {
                        Located(account: $0, location: location, itemKey: row.account)
                    }
                }
            } catch let error as ClaudeKeychain.KeychainError
                        where error.status == errSecMissingEntitlement {
                if location == .shared { sharedReachable = false }
                continue
            } catch {
                if location == .shared { sharedReachable = false }
                if firstFailure == nil { firstFailure = error }
            }
        }
        found += await migrate(legacy, alreadyStored: Set(found.map(\.account.itemKey)))
        if found.isEmpty, let firstFailure { throw firstFailure }
        let placement = Placement(of: found, sharedReachable: sharedReachable) {
            ClaudeLoginIdentity.current()
        }
        return await settle(placement).sorted {
            ($0.account.name, $0.account.kind.title) < ($1.account.name, $1.account.kind.title)
        }
    }

    /// What `all()` makes of the records it read: which to list as they are,
    /// which to move to their kind's keychain first, and which to retire.
    ///
    /// Logins in iCloud Keychain are what this rule exists to end, and they are
    /// handled with care: one of them may be another Mac's live login, so it is
    /// never listed here (this Mac would refresh it, signing the other out) and
    /// never deleted (that would take the other Mac's saved copy). The one
    /// exception is a login this Mac is itself logged in as, with no saved copy
    /// of its own yet: that is this Mac's to claim, and it moves here.
    struct Placement {
        /// Already in their kind's keychain, or with nowhere better to go.
        var settled: [Located] = []
        /// To be written to their kind's keychain and deleted from this one.
        var moving: [Located] = []
        /// Local twins of setup tokens already in iCloud Keychain, to delete.
        var redundant: [Located] = []

        /// `liveIdentity` is asked only when iCloud Keychain holds a login:
        /// `~/.claude.json` is most of a megabyte, and a listing with nothing to
        /// claim has no reason to parse it.
        init(
            of found: [Located], sharedReachable: Bool,
            liveIdentity: () -> ClaudeLoginIdentity
        ) {
            let sharedLogins = found.filter { $0.location == .shared && $0.account.kind == .oauth }
            var claimed: String?
            if !sharedLogins.isEmpty {
                let live = liveIdentity()
                let savedHere = found.contains {
                    $0.location == .login && $0.account.isLogin(of: live)
                }
                if !savedHere {
                    claimed = ClaudeAccountKeychainStore.savedLogin(for: live, in: sharedLogins)?.itemKey
                }
            }
            for record in found {
                // A legacy item still addressed by its bare name may hold two
                // records, and deleting it to move one would lose the other.
                guard record.itemKey == record.account.itemKey else {
                    settled.append(record)
                    continue
                }
                switch (record.account.kind, record.location) {
                case (.oauth, .login), (.longLived, .shared):
                    settled.append(record)
                case (.oauth, .shared):
                    if record.itemKey == claimed { moving.append(record) }
                case (.longLived, .login):
                    let twinShared = found.contains {
                        $0.location == .shared && $0.itemKey == record.itemKey
                    }
                    if !sharedReachable {
                        settled.append(record)
                    } else if twinShared {
                        redundant.append(record)
                    } else {
                        moving.append(record)
                    }
                }
            }
        }
    }

    /// Carries out `placement` and returns what to list. Best-effort, like the
    /// legacy migration: a record whose move fails is listed from where it is,
    /// and the next read tries again.
    private static func settle(_ placement: Placement) async -> [Located] {
        var listed = placement.settled
        for record in placement.moving {
            let home = ClaudeKeychainLocation.home(of: record.account.kind)
            do {
                try await write(record.account, to: home)
                try? await ClaudeKeychain.delete(
                    service: ClaudeKeychain.savedAccountsService, account: record.itemKey,
                    location: record.location)
                listed.append(Located(account: record.account, location: home, itemKey: record.itemKey))
            } catch {
                logger.error("""
                    accounts: couldn't move \(record.itemKey, privacy: .public) to \
                    \(home.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)
                    """)
                listed.append(record)
            }
        }
        for twin in placement.redundant {
            try? await ClaudeKeychain.delete(
                service: ClaudeKeychain.savedAccountsService, account: twin.itemKey,
                location: twin.location)
        }
        return listed
    }

    /// Rewrites legacy bare-name items as one item per credential kind, then
    /// deletes the bare item once every record in it has somewhere else to live.
    ///
    /// Best-effort by design: this runs inside a plain listing, so a keychain
    /// that refuses the write must still yield a readable list. A record whose
    /// write failed is returned addressed by the bare item it is still in.
    ///
    /// A record whose canonical key was already found in this same read is
    /// skipped, never written: the kind-keyed item is what the current code
    /// wrote, and the legacy copy is by definition the older of the two.
    private static func migrate(
        _ legacy: [LegacyItem], alreadyStored: Set<String>
    ) async -> [Located] {
        var migrated: [Located] = []
        var stored = alreadyStored
        for item in legacy {
            var allPlaced = true
            for record in item.records where !stored.contains(record.itemKey) {
                do {
                    try await write(record, to: item.location)
                    stored.insert(record.itemKey)
                    migrated.append(Located(
                        account: record, location: item.location, itemKey: record.itemKey))
                } catch {
                    allPlaced = false
                    migrated.append(Located(
                        account: record, location: item.location, itemKey: item.itemKey))
                }
            }
            guard allPlaced else { continue }
            try? await ClaudeKeychain.delete(
                service: ClaudeKeychain.savedAccountsService, account: item.itemKey,
                location: item.location)
        }
        return migrated
    }

    /// Stores `account` in its kind's keychain (`ClaudeKeychainLocation
    /// .home(of:)`), replacing the record of that name *and kind* there — the
    /// other kind under the same name is untouched — and returns where it went.
    ///
    /// A setup token's copy on this Mac is deleted once it is in iCloud
    /// Keychain, so the list never draws it twice. A login's copy in iCloud
    /// Keychain is NOT deleted: it may be another Mac's saved login, and the
    /// listing already leaves it out (`Placement`).
    ///
    /// A build without the Keychain Sharing entitlement can't reach iCloud
    /// Keychain at all, and a setup token kept on this Mac still works here, so
    /// that is where it goes.
    @discardableResult
    public static func save(_ account: ClaudeSavedAccount) async throws -> ClaudeKeychainLocation {
        let home = ClaudeKeychainLocation.home(of: account.kind)
        do {
            try await write(account, to: home)
        } catch let error as ClaudeKeychain.KeychainError
                    where error.status == errSecMissingEntitlement && home == .shared {
            try await write(account, to: .login)
            return .login
        }
        if home == .shared {
            try? await ClaudeKeychain.delete(
                service: ClaudeKeychain.savedAccountsService, account: account.itemKey,
                location: .login)
        }
        return home
    }

    /// The one place a record becomes keychain bytes, shared by `save` and the
    /// migration so the two cannot drift on key or label.
    private static func write(
        _ account: ClaudeSavedAccount, to location: ClaudeKeychainLocation
    ) async throws {
        try await ClaudeKeychain.write(
            service: ClaudeKeychain.savedAccountsService, account: account.itemKey,
            location: location, label: ClaudeAccounts.configuration.itemLabel(name: account.name, kind: account.kind),
            data: try JSONEncoder().encode(account))
    }

    /// Removes one credential from wherever it is. Both locations are asked, so
    /// a delete cannot leave behind a copy saved before credentials were kept
    /// by kind — which the next read would otherwise move back into the list.
    ///
    /// Takes the item key, not a name: a name is two possible records, and
    /// deleting the login when the user selected the setup token is exactly the
    /// conflation this store no longer makes.
    public static func delete(itemKey: String) async throws {
        var firstFailure: Error?
        for location in ClaudeKeychainLocation.allCases {
            do {
                try await ClaudeKeychain.delete(
                    service: ClaudeKeychain.savedAccountsService, account: itemKey,
                    location: location)
            } catch let error as ClaudeKeychain.KeychainError
                        where error.status == errSecMissingEntitlement {
                continue
            } catch {
                if firstFailure == nil { firstFailure = error }
            }
        }
        if let firstFailure { throw firstFailure }
    }

    /// One saved credential by the item it lives in, with its location.
    public static func find(itemKey: String) async throws -> Located? {
        try await all().first { $0.itemKey == itemKey }
    }

    /// One saved credential by account name and kind.
    public static func find(name: String, kind: ClaudeCredentialKind) async throws -> Located? {
        try await all().first { $0.account.name == name && $0.account.kind == kind }
    }

    // MARK: - Claude Code's own login

    /// The login Claude Code is using right now.
    ///
    /// Always the login keychain: this is Claude Code's item, not the app's,
    /// and where it lives is Claude Code's decision. Read through `security(1)`,
    /// the way `claude` reads it, so it never raises a prompt — see
    /// `ClaudeCodeKeychainItem`.
    public static func currentLogin() async throws -> ClaudeOAuthCredential? {
        guard let data = try await ClaudeCodeKeychainItem.read(account: NSUserName())
        else { return nil }
        return try ClaudeCredentialBlob(data: data).oauth()
    }

    /// The saved login record for `identity`.
    ///
    /// The same rule the account list uses to mark the current login
    /// (`ClaudeSavedAccount.isLogin(of:)`), so the record a round syncs is always
    /// the one the user sees checked: uuid first, then name or captured email,
    /// ignoring case. A uuid match is preferred over a name match, because a
    /// renamed login and a stale one can share a name.
    public static func savedLogin(
        for identity: ClaudeLoginIdentity, in located: [Located]
    ) -> Located? {
        let logins = located.filter { $0.account.isLogin(of: identity) }
        return logins.first { !$0.account.accountUUID.isEmpty } ?? logins.first
    }

    /// How Claude Code's live pair and the saved copy of the same account stand
    /// against each other.
    public enum LiveLoginStanding: Equatable {
        /// Byte-for-byte the same pair — nothing to do.
        case same
        /// The live pair is the newer one: the saved copy gets it.
        case liveNewer
        /// The saved copy is newer — it was refreshed apart from Claude Code
        /// (a login claimed from iCloud Keychain, saved there by a build that
        /// still shared logins, may have been), which voided the pair Claude
        /// Code holds here.
        case savedNewer
        /// The live pair's refresh token is another saved record's. The identity
        /// in `~/.claude.json` and the credential in Claude Code's item disagree,
        /// and filing the pair under the identity would overwrite one account's
        /// login with another's.
        case foreign
    }

    /// Where `live` stands against `saved`, the record `savedLogin(for:in:)`
    /// picked for the live identity.
    ///
    /// Newer is judged by access-token expiry: every refresh mints a later one,
    /// and the refresh that produced the later pair is the one that voided the
    /// other. An unknown expiry on either side keeps the live pair — it is the one
    /// in use.
    public static func standing(
        of live: ClaudeOAuthCredential, against saved: Located, among located: [Located]
    ) -> LiveLoginStanding {
        if saved.account.oauth == live { return .same }
        let heldElsewhere = located.contains {
            $0.itemKey != saved.itemKey && $0.account.kind == .oauth
                && $0.account.oauth?.refreshToken == live.refreshToken
        }
        if heldElsewhere { return .foreign }
        if let savedExpiry = saved.account.oauth?.expirySeconds,
           let liveExpiry = live.expirySeconds, savedExpiry > liveExpiry {
            return .savedNewer
        }
        return .liveNewer
    }

    /// Brings Claude Code's live login and the saved record for the account it is
    /// logged in as into agreement, and returns that record as now stored.
    ///
    /// **Why this exists: a refresh token is single-use, and the live login and
    /// its saved copy start out holding the same one.** Claude Code refreshes its
    /// own login every eight hours or so, and each refresh voids the token it
    /// spent — so a saved copy taken once and never updated is dead the first time
    /// Claude Code refreshes, and switching back to it installs a login that
    /// answers "login expired". This keeps the saved copy on the live one's
    /// current pair.
    ///
    /// The newer pair wins, in whichever direction that is. A saved copy
    /// refreshed apart from Claude Code voided the pair Claude Code holds here;
    /// copying that dead pair over the good one would leave the account dead, so
    /// instead the newer saved pair is installed into Claude Code's item.
    ///
    /// Only an EXISTING record is updated. Whether an account is saved at all is
    /// autosave's decision (or the user's), not a side effect of reading it.
    /// Returns nil when there is no live login, no record to update, or the live
    /// pair belongs to a different record (`.foreign`).
    @discardableResult
    public static func syncSavedCopyOfLiveLogin(
        _ identity: ClaudeLoginIdentity, in located: [Located]
    ) async throws -> Located? {
        guard let saved = savedLogin(for: identity, in: located),
              let item = try await ClaudeCodeKeychainItem.read(account: NSUserName())
        else { return nil }
        var blob = try ClaudeCredentialBlob(data: item)
        guard let live = try blob.oauth() else { return nil }
        switch standing(of: live, against: saved, among: located) {
        case .same:
            return saved
        case .foreign:
            return nil
        case .liveNewer:
            return try await file(live, over: saved)
        case .savedNewer:
            guard let newer = saved.account.oauth else { return saved }
            try blob.setOAuth(newer)
            try await ClaudeCodeKeychainItem.update(account: NSUserName(), data: try blob.serialized())
            return saved
        }
    }

    /// `saved` with `oauth` stored as its login.
    private static func file(
        _ oauth: ClaudeOAuthCredential, over saved: Located
    ) async throws -> Located {
        var account = saved.account
        account.oauth = oauth
        let location = try await save(account)
        return Located(account: account, location: location, itemKey: account.itemKey)
    }

    /// Makes `oauth` the login Claude Code uses and `accountBlock` the account
    /// `~/.claude.json` names — after filing the outgoing login's current pair
    /// into its saved record.
    ///
    /// **One read of Claude Code's item for all of it.** The outgoing pair is
    /// taken from the same bytes that are then edited and written back, so
    /// nothing Claude Code does between two reads can slip past the capture.
    ///
    /// **A failure to file the outgoing login stops the switch** before anything
    /// is written: Claude Code's item holds the only copy of that account's
    /// current refresh token, and overwriting it uncaptured leaves the saved
    /// login dead ("login expired" on the way back, 2.159.2).
    ///
    /// The blob is **edited, never replaced**: beside the login it holds
    /// `mcpOAuth`, the authorizations for every MCP server the user connected.
    /// And if there is no item to edit, this fails rather than creating one — the
    /// login is Claude Code's to create.
    ///
    /// **The keychain and `~/.claude.json` move together or not at all.** A
    /// credential for one account under the other's identity is what a round
    /// would then file under the wrong record, so a config write that fails puts
    /// the original item bytes back.
    public static func switchLiveLogin(
        from outgoing: ClaudeLoginIdentity, in located: [Located],
        to oauth: ClaudeOAuthCredential, accountBlock: String
    ) async throws {
        let account = NSUserName()
        guard let original = try await ClaudeCodeKeychainItem.read(account: account) else {
            throw ClaudeCodeKeychainItem.ItemError.failed(
                operation: "switch Claude Code's login",
                message: "it has no saved login on this Mac to replace. "
                    + "Sign in with `claude` once first")
        }
        var blob = try ClaudeCredentialBlob(data: original)
        if let live = try blob.oauth(), let saved = savedLogin(for: outgoing, in: located),
           standing(of: live, against: saved, among: located) == .liveNewer {
            _ = try await file(live, over: saved)
        }
        try blob.setOAuth(oauth)
        try await ClaudeCodeKeychainItem.update(account: account, data: try blob.serialized())
        do {
            try ClaudeLoginIdentity.installAccountBlock(accountBlock)
        } catch {
            try? await ClaudeCodeKeychainItem.update(account: account, data: original)
            throw error
        }
    }
}

extension ClaudeAccountKeychainStore: Loggable {
    public static let logger = makeLogger()
}

extension ClaudeSavedAccount {

    /// Whether this saved record is the login `identity` names.
    ///
    /// Answered from `~/.claude.json`'s identity, not by comparing tokens:
    /// comparing would mean reading Claude Code's keychain item on every redraw.
    /// The uuid is preferred over the email because it survives an email change,
    /// which is the case where a name comparison quietly starts lying; names are
    /// compared ignoring case, because an email is.
    public func isLogin(of identity: ClaudeLoginIdentity) -> Bool {
        guard kind == .oauth, !identity.isEmpty else { return false }
        if !accountUUID.isEmpty, !identity.uuid.isEmpty {
            return accountUUID == identity.uuid
        }
        let current = identity.displayName.lowercased()
        return name.lowercased() == current
            || (!self.identity.isEmpty && self.identity.lowercased() == current)
    }
}
