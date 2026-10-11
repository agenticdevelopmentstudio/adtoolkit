import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS
import os

/// A round avatar: the user's picture when it loads, their initials on a
/// themed circle until then and whenever it does not.
@MainActor
final class AccountAvatarView: NSView {
    static let side: CGFloat = 48
    private static var cache: [URL: NSImage] = [:]

    private let circle = ThemedBackgroundView(role: .accent)
    private let initialsLabel = ThemedLabel(role: .onAccentText, textRole: .heading, weight: .semibold)
    private let imageView = NSImageView()
    private var loadTask: Task<Void, Never>?

    var user: AccountUser? {
        didSet { if user != oldValue { render() } }
    }

    init() {
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
        initialsLabel.stringValue = user?.initials ?? ""
        setAccessibilityLabel(user.map { "Avatar for \($0.name)" })
        guard let url = user?.avatarURL else {
            imageView.image = nil
            imageView.isHidden = true
            return
        }
        if let cached = Self.cache[url] {
            imageView.image = cached
            imageView.isHidden = false
            return
        }
        imageView.isHidden = true
        loadTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let image = NSImage(data: data) else { return }
                Self.cache[url] = image
                guard let self, self.user?.avatarURL == url else { return }
                self.imageView.image = image
                self.imageView.isHidden = false
            } catch {
                Self.logger.debug("avatar load failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

extension AccountAvatarView: Loggable {
    static nonisolated let logger = makeLogger()
}
