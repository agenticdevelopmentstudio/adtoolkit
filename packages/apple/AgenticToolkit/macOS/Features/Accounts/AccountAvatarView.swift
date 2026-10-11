import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS
import os

/// A round avatar: the user's picture when it loads, their initials on a
/// themed circle until then and whenever it does not.
///
/// There is no cache of its own: the default fetch goes through
/// `URLSession.shared`, whose HTTP cache follows the server's caching
/// headers, so a picture replaced at the same URL is picked up when they say.
@MainActor
final class AccountAvatarView: NSView {
    /// Fetches a picture's bytes and the response that came with them.
    typealias Fetch = @Sendable (URL) async throws -> (Data, URLResponse)

    static let side: CGFloat = 48

    private let circle = ThemedBackgroundView(role: .accent)
    private let initialsLabel = ThemedLabel(role: .onAccentText, textRole: .heading, weight: .semibold)
    private let imageView = NSImageView()
    private let fetch: Fetch
    /// The load in flight, if any; nil once it settles, so a later showing can retry.
    private(set) var loadTask: Task<Void, Never>?

    var user: AccountUser? {
        didSet { if user != oldValue { render() } }
    }

    /// True while the user's picture, not their initials, is on screen.
    var showsPicture: Bool { !imageView.isHidden && imageView.image != nil }

    init(fetch: @escaping Fetch = { try await URLSession.shared.data(from: $0) }) {
        self.fetch = fetch
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setAccessibilityIdentifier("accounts.detail.avatar")
        setAccessibilityRole(.image)
        for sub in [circle, imageView] as [NSView] {
            sub.translatesAutoresizingMaskIntoConstraints = false
            sub.wantsLayer = true
            sub.layer?.cornerRadius = Self.side / 2
            sub.layer?.masksToBounds = true
            addSubview(sub)
        }
        initialsLabel.alignment = .center
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(initialsLabel)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.side),
            heightAnchor.constraint(equalToConstant: Self.side),
            circle.leadingAnchor.constraint(equalTo: leadingAnchor),
            circle.trailingAnchor.constraint(equalTo: trailingAnchor),
            circle.topAnchor.constraint(equalTo: topAnchor),
            circle.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            initialsLabel.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: circle.centerYAnchor)
        ])
        render()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func render() {
        loadTask?.cancel()
        loadTask = nil
        imageView.image = nil
        imageView.isHidden = true
        initialsLabel.stringValue = user?.initials ?? ""
        setAccessibilityLabel(user.map { "Avatar for \($0.name)" })
        load()
    }

    /// Showing the view again retries a picture that has not loaded, such as
    /// one that failed while the Mac was offline.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil, !showsPicture { load() }
    }

    private func load() {
        guard loadTask == nil, let url = user?.avatarURL else { return }
        let fetch = self.fetch
        loadTask = Task { [weak self] in
            let image = await Self.picture(at: url, fetch: fetch)
            // A cancelled load was replaced by render(), which owns loadTask now.
            guard !Task.isCancelled, let self else { return }
            self.loadTask = nil
            guard let image else { return }
            self.imageView.image = image
            self.imageView.isHidden = false
        }
    }

    /// The picture at `url`, or nil, logged, when the fetch fails, the server
    /// answers with anything but a 2xx, or the bytes are not an image.
    private static func picture(at url: URL, fetch: Fetch) async -> NSImage? {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await fetch(url)
        } catch {
            if !(error is CancellationError) {
                logger.debug("avatar load failed: \(error.localizedDescription, privacy: .public)")
            }
            return nil
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            logger.debug("avatar load got HTTP \(http.statusCode, privacy: .public)")
            return nil
        }
        guard let image = NSImage(data: data) else {
            logger.debug("avatar data is not an image (\(data.count, privacy: .public) bytes)")
            return nil
        }
        return image
    }
}

extension AccountAvatarView: Loggable {
    static nonisolated let logger = makeLogger()
}
