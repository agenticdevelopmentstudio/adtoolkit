import Foundation
import AgenticToolkitCore
import UserNotifications
import os

/// Records something for the owner as an attention item and, when the item's
/// kind is one the owner asked to hear about, posts a macOS notification.
@MainActor
public final class PartnerNotifier {

    private let store: PartnerStore
    private let settings: SettingsStore
    private let post: @MainActor (_ title: String, _ body: String) -> Void

    public init(store: PartnerStore, settings: SettingsStore = UserSettings.shared,
                post: @escaping @MainActor (_ title: String, _ body: String) -> Void
                    = PartnerNotifier.postSystemNotification) {
        self.store = store
        self.settings = settings
        self.post = post
    }

    /// Stores the item, then posts a notification unless `kind` is switched off in
    /// ``UserSettings/partnerNotifyKinds``. The item is kept either way.
    @discardableResult
    public func notify(kind: AttentionKind = .notification, title: String, body: String,
                       reference: [String: String] = [:], createdBy: String) throws -> AttentionItem {
        let text = body.isEmpty ? title : "\(title)\n\(body)"
        let item = AttentionItem(kind: kind, text: text, reference: reference, createdBy: createdBy)
        try store.insert(item)
        if settings.get(UserSettings.partnerNotifyKinds).contains(kind.rawValue) {
            post(title, body)
        }
        return item
    }

    public static func postSystemNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: "partner-\(UUID().uuidString)", content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Self.logger.error("Partner notification failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

extension PartnerNotifier: Loggable {
    public static nonisolated let logger = makeLogger()
}
