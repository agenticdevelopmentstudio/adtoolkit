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

    /// The one permission request this process makes; every post waits for it.
    private static var authorization: Task<Void, Never>?

    /// Asks for alert and sound permission once per process, then posts. macOS shows its prompt only the
    /// first time ever; afterwards the request returns the owner's standing answer at once. A notification
    /// refused there is not shown, and the attention item already written still carries it.
    /// Outside an app bundle (a test runner, a command-line host) the notification center traps on first
    /// use, so nothing is posted there; the attention item still records it.
    public static func postSystemNotification(title: String, body: String) {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            logger.notice("Not an app bundle, so no system notification for: \(title, privacy: .public)")
            return
        }
        let asked = authorization ?? Task { @MainActor in
            do {
                let center = UNUserNotificationCenter.current()
                if try await !center.requestAuthorization(options: [.alert, .sound]) {
                    logger.notice("Partner notifications are not allowed; attention items still record them")
                }
            } catch {
                logger.error("Partner notification permission failed: \(error.localizedDescription)")
            }
        }
        authorization = asked
        Task { @MainActor in
            await asked.value
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let request = UNNotificationRequest(identifier: "partner-\(UUID().uuidString)", content: content,
                                                trigger: nil)
            do { try await center.add(request) } catch {
                logger.error("Partner notification failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

extension PartnerNotifier: Loggable {
    public static nonisolated let logger = makeLogger()
}
