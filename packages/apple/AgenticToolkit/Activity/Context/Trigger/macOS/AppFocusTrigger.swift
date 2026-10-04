#if os(macOS)
import AppKit
import Foundation
import UniformTypeIdentifiers

public struct DocumentMetadata: Sendable, Equatable {
    public let size: Int64?
    public let modifiedAt: Date?
    /// A UTI (`public.swift-source`), not a file extension — stable across
    /// platforms and already what Spotlight and the rest of macOS speak.
    public let type: String?
    public init(size: Int64?, modifiedAt: Date?, type: String?) {
        self.size = size; self.modifiedAt = modifiedAt; self.type = type
    }
}

/// A seam so the trigger can be tested without a real filesystem.
public protocol DocumentMetadataReading: Sendable {
    func metadata(forPath path: String) -> DocumentMetadata?
}

public struct FileDocumentMetadataReader: DocumentMetadataReading {
    public init() {}
    /// Returns `nil` for anything unreadable — a path that does not exist, one
    /// the daemon has no access to, or a directory — rather than throwing: a
    /// focus event is still worth recording without its document metadata.
    ///
    /// The path is symlink-resolved first because `attributesOfItem` does NOT
    /// traverse links — it reports on the link itself, whose "size" is the
    /// byte length of its destination path. Recording that as the document's
    /// size would be worse than recording nothing. The target is the document
    /// the user is actually editing, so that is what we measure.
    ///
    /// `type` is derived from the path string alone and costs no additional
    /// filesystem call, which matters because a focus change is a hot path.
    public func metadata(forPath path: String) -> DocumentMetadata? {
        let resolved = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: resolved) else { return nil }
        return DocumentMetadata(
            size: (attrs[.size] as? NSNumber)?.int64Value,
            modifiedAt: attrs[.modificationDate] as? Date,
            type: UTType(filenameExtension: (path as NSString).pathExtension)?.identifier)
    }
}

/// Emits an `app_focus` event whenever the frontmost app or its focused window
/// changes.
///
/// A thin adapter over the existing, already-tested `FocusSource` rather than a
/// second AX implementation — the observation logic (`FrontmostFocusAdapter`)
/// stays in one place, and this trigger adds only the fields the usage pipeline
/// does not collect: the executable path and the focused document's size, mtime
/// and type.
@MainActor
public final class AppFocusTrigger: ContextTrigger {
    public let kind: ContextEventKind = .appFocus
    public let requiredPermission: ContextPermission = .accessibility
    public var onEvent: ((ContextEventDetail, Date) -> Void)?

    private let source: any FocusSource
    /// Optional second observation, purely as a nudge (I-3): switching a
    /// browser tab retitles the frontmost window without activating any
    /// application, so `NSWorkspace.didActivateApplicationNotification` never
    /// fires and `source` alone reports nothing. This trigger consumes only
    /// `onTitleChange` from it and never its `onEvent` — the resulting row is
    /// an `app_focus` row, which is what "apps and windows you switch to"
    /// consents to; window rows remain `WindowLifecycleContextTrigger`'s and
    /// require that trigger's own opt-in.
    ///
    /// It is owned here rather than wired externally because it must be live
    /// exactly while *this* trigger is running — the previous wiring lived on
    /// the usage pipeline's adapters and was dead whenever usage capture was
    /// off, which is the default.
    private let titleSource: (any WindowLifecycleSource)?
    private let metadata: any DocumentMetadataReading
    private let executablePath: @Sendable (Int32) -> String?
    private let now: () -> Date
    private var isRunning = false

    /// Identity of the last focus actually emitted, so an unchanged reading is
    /// not written again.
    ///
    /// `onTitleChange` fires for *any* window on the machine being retitled —
    /// a background download counter, a clock in another app's title bar — and
    /// each one polls and re-emits the frontmost focus, which has not changed.
    /// On this machine that was the single largest source of rows in the log.
    /// Compared on identity only: the document metadata is derived from
    /// `documentPath` and re-reading it is exactly the cost being avoided.
    private var lastEmitted: FocusIdentity?

    private struct FocusIdentity: Equatable {
        let bundleID: String
        let pid: Int32
        let windowID: UInt32?
        let windowTitle: String?
        let documentPath: String?
        /// Part of the identity, so that browsing from one page to the next
        /// inside a single window is recorded rather than deduplicated away.
        /// Without it, a site whose tab title never changes would look like
        /// one uninterrupted visit.
        let url: String?
    }

    public init(source: any FocusSource = FrontmostFocusAdapter(),
                titleSource: (any WindowLifecycleSource)? = nil,
                metadata: any DocumentMetadataReading = FileDocumentMetadataReader(),
                executablePath: @escaping @Sendable (Int32) -> String? = AppFocusTrigger.systemExecutablePath,
                now: @escaping () -> Date = { Date() }) {
        self.source = source
        self.titleSource = titleSource
        self.metadata = metadata
        self.executablePath = executablePath
        self.now = now
    }

    public nonisolated static func systemExecutablePath(_ pid: Int32) -> String? {
        NSRunningApplication(processIdentifier: pid)?.executableURL?.path
    }

    public func start() throws {
        guard !isRunning else { return }
        isRunning = true
        source.onFocus = { [weak self] focus in self?.emit(focus) }
        source.start()
        if let titleSource {
            // `poll()`, not a stored focus: the title has just changed, so the
            // point is to re-read the current window rather than replay a
            // stale one.
            titleSource.onTitleChange = { [weak self] in self?.source.poll() }
            titleSource.start()
        }
    }

    /// Guarded by `isRunning`, symmetrically with `start()`: `titleSource` may
    /// be a `SharedWindowLifecycleSource` whose start/stop calls are counted,
    /// and an unbalanced `stop()` here would switch off an observation that
    /// `WindowLifecycleContextTrigger` is still using.
    public func stop() {
        guard isRunning else { return }
        isRunning = false
        // Cleared so a restart records its opening focus rather than
        // deduplicating it against a reading from the previous run.
        lastEmitted = nil
        source.onFocus = nil
        source.stop()
        titleSource?.onTitleChange = nil
        titleSource?.stop()
    }

    private func emit(_ focus: WindowFocus) {
        guard isRunning else { return }
        // The adapter reports 0 / "" for "the app exposed nothing". Those are
        // absences, and NULL is how the schema says absent — storing both 0
        // and NULL for the same fact would make queries lie.
        let windowID = focus.windowID == 0 ? nil : focus.windowID
        let windowTitle = focus.title.isEmpty ? nil : focus.title

        let identity = FocusIdentity(
            bundleID: focus.app.bundleID, pid: focus.app.pid, windowID: windowID,
            windowTitle: windowTitle, documentPath: focus.documentPath, url: focus.url)
        // Checked before the document metadata is read, so a re-poll of an
        // unchanged focus costs no filesystem call either.
        guard identity != lastEmitted else { return }
        lastEmitted = identity

        let doc = focus.documentPath.flatMap { metadata.metadata(forPath: $0) }
        onEvent?(.appFocus(AppFocusDetail(
            bundleID: focus.app.bundleID,
            appName: focus.app.name,
            pid: focus.app.pid,
            executablePath: executablePath(focus.app.pid),
            windowID: windowID,
            windowTitle: windowTitle,
            documentPath: focus.documentPath,
            documentSize: doc?.size,
            documentModifiedAt: doc?.modifiedAt,
            documentType: doc?.type,
            url: focus.url)), now())
    }
}
#endif
