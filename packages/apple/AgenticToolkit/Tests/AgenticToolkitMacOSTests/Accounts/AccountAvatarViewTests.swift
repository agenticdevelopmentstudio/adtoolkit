import AppKit
import Foundation
import Testing
@testable import AgenticToolkitMacOS
import AgenticToolkitCore

/// Counts fetches, and answers each from the list of replies in turn (the last
/// one repeats).
private final class Server: @unchecked Sendable {
    enum Reply { case status(Int, Data), offline }
    private let lock = NSLock()
    private var replies: [Reply]
    private var count = 0
    var calls: Int { lock.withLock { count } }

    init(_ replies: Reply...) { self.replies = replies }

    func fetch(_ url: URL) throws -> (Data, URLResponse) {
        let reply = lock.withLock {
            count += 1
            return replies.count > 1 ? replies.removeFirst() : replies[0]
        }
        switch reply {
        case .offline:
            throw URLError(.notConnectedToInternet)
        case .status(let code, let data):
            return (data, HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!)
        }
    }
}

private let picture: Data = {
    let image = NSImage(size: NSSize(width: 2, height: 2))
    image.lockFocus()
    NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 2, height: 2))
    image.unlockFocus()
    return image.tiffRepresentation!
}()

private let ada = AccountUser(
    id: "u1", name: "Ada Lovelace", email: "ada@x.y", avatarURL: URL(string: "https://x.y/a.png")
)

@Suite("AccountAvatarView")
@MainActor
struct AccountAvatarViewTests {
    private func make(_ server: Server) -> AccountAvatarView {
        AccountAvatarView(fetch: { try server.fetch($0) })
    }

    private func show(_ view: AccountAvatarView, user: AccountUser = ada) async {
        view.user = user
        await view.loadTask?.value
    }

    @Test("a picture the server sends replaces the initials")
    func loads() async {
        let view = make(Server(.status(200, picture)))
        await show(view)
        #expect(view.showsPicture)
    }

    @Test("an error page is never shown as the picture, even one that decodes")
    func refusesNon2xx() async {
        let view = make(Server(.status(404, picture)))
        await show(view)
        #expect(!view.showsPicture)
    }

    @Test("bytes that are not an image leave the initials up")
    func refusesUndecodable() async {
        let view = make(Server(.status(200, Data("<html>".utf8))))
        await show(view)
        #expect(!view.showsPicture)
    }

    @Test("a picture that failed to load is fetched again when the view is shown")
    func retriesWhenShown() async {
        let server = Server(.offline, .status(200, picture))
        let view = make(server)
        await show(view)
        #expect(!view.showsPicture)

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                              styleMask: .titled, backing: .buffered, defer: true)
        window.contentView?.addSubview(view)
        await view.loadTask?.value

        #expect(server.calls == 2)
        #expect(view.showsPicture)
    }

    @Test("showing a loaded picture again does not fetch it again")
    func noRefetchWhenLoaded() async {
        let server = Server(.status(200, picture))
        let view = make(server)
        await show(view)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                              styleMask: .titled, backing: .buffered, defer: true)
        window.contentView?.addSubview(view)
        #expect(view.loadTask == nil)
        #expect(server.calls == 1)
    }

    @Test("a user without a picture shows initials and fetches nothing")
    func noURL() async {
        let server = Server(.status(200, picture))
        let view = make(server)
        await show(view, user: AccountUser(id: "u2", name: "Zoe", email: "z@x.y", avatarURL: nil))
        #expect(!view.showsPicture)
        #expect(server.calls == 0)
    }
}
