import Foundation

/// Who is signed in to an account, as much as an accounts UI needs to show.
public struct AccountUser: Sendable, Equatable {
    public let id: String
    public let name: String
    public let email: String
    public let avatarURL: URL?

    public init(id: String, name: String, email: String, avatarURL: URL?) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
    }

    /// Up to two initials from the name's first two words, else the email's
    /// first letter, else "?" — never empty, so an avatar always has a face.
    public var initials: String {
        let words = name.split(whereSeparator: { $0.isWhitespace }).prefix(2)
        let letters = words.compactMap { $0.first.map { String($0).uppercased() } }
        if !letters.isEmpty { return letters.joined() }
        return email.first.map { String($0).uppercased() } ?? "?"
    }
}

/// Where an account stands. `busy` covers work the account started itself
/// (signing out); sign-in progress lives inside the account's own sheet.
public enum AccountState: Sendable, Equatable {
    case restoring
    case signedOut
    case busy
    case signedIn(AccountUser)
}

/// What a platform hands an account so it can present its own sign-in UI:
/// an `NSWindow` or `NSViewController` on macOS, a `UIViewController` on iOS.
/// Held weakly and type-erased so this Foundation-only tier imports neither
/// AppKit nor UIKit.
public struct AccountPresentationAnchor {
    public private(set) weak var object: AnyObject?

    public init(_ object: AnyObject) {
        self.object = object
    }
}

/// One sign-in-able account an app knows about. The accounts panel renders
/// from these properties and calls these verbs; how an account signs in is
/// its own business, which is why login is "present your sign-in UI" rather
/// than a credentials method.
@MainActor
public protocol Account: AnyObject {
    var id: String { get }
    var displayName: String { get }
    /// One line shown under the title while signed out.
    var summary: String { get }
    var state: AccountState { get }
    /// An error or status line; `nil` when there is none.
    var message: String? { get }
    /// Where to sign up on the web; `nil` hides Signup.
    var signupURL: URL? { get }
    /// Fires after any change to `state` or `message`.
    var onChange: @MainActor () -> Void { get set }

    func presentSignIn(from anchor: AccountPresentationAnchor)
    func signOut() async
}
