#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity

private struct ScriptedMetadata: DocumentMetadataReading {
    let byPath: [String: DocumentMetadata]
    func metadata(forPath path: String) -> DocumentMetadata? { byPath[path] }
}

@MainActor
final class AppFocusTriggerTests: XCTestCase {
    private func makeTrigger(metadata: [String: DocumentMetadata] = [:],
                             exePath: @escaping @Sendable (Int32) -> String? = { _ in "/bin/x" })
    -> (AppFocusTrigger, FakeFocusSource, [ContextEventDetail]) {
        let source = FakeFocusSource()
        let trigger = AppFocusTrigger(source: source,
                                      metadata: ScriptedMetadata(byPath: metadata),
                                      executablePath: exePath,
                                      now: { Date(timeIntervalSince1970: 7_000) })
        return (trigger, source, [])
    }

    func testDeclaresItsKindAndPermission() {
        let (t, _, _) = makeTrigger()
        XCTAssertEqual(t.kind, ContextEventKind.appFocus)
        XCTAssertEqual(t.requiredPermission, ContextPermission.accessibility)
    }

    func testMapsAFocusOntoAnAppFocusDetail() throws {
        let (t, source, _) = makeTrigger()
        var captured: [(ContextEventDetail, Date)] = []
        t.onEvent = { captured.append(($0, $1)) }
        try t.start()
        source.emit(WindowFocus(app: AppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", pid: 42),
                                windowID: 9, title: "main.swift", documentPath: nil))

        XCTAssertEqual(captured.count, 1)
        guard case .appFocus(let d) = captured[0].0 else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.bundleID, "com.apple.dt.Xcode")
        XCTAssertEqual(d.appName, "Xcode")
        XCTAssertEqual(d.pid, 42)
        XCTAssertEqual(d.windowID, 9)
        XCTAssertEqual(d.windowTitle, "main.swift")
        XCTAssertEqual(d.executablePath, "/bin/x")
        XCTAssertEqual(captured[0].1, Date(timeIntervalSince1970: 7_000))
    }

    func testEnrichesADocumentPathWithFileMetadata() throws {
        let meta = DocumentMetadata(size: 4_096,
                                    modifiedAt: Date(timeIntervalSince1970: 8_000),
                                    type: "public.swift-source")
        let (t, source, _) = makeTrigger(metadata: ["/tmp/main.swift": meta])
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        source.emit(WindowFocus(app: AppInfo(bundleID: "b", name: "A", pid: 1),
                                windowID: 2, title: "t", documentPath: "/tmp/main.swift"))

        guard case .appFocus(let d) = captured[0] else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.documentPath, "/tmp/main.swift")
        XCTAssertEqual(d.documentSize, 4_096)
        XCTAssertEqual(d.documentModifiedAt, Date(timeIntervalSince1970: 8_000))
        XCTAssertEqual(d.documentType, "public.swift-source")
    }

    func testAnUnreadableDocumentStillEmitsTheFocusEvent() throws {
        // The focus itself is the signal; missing file metadata must not cost
        // us the event.
        let (t, source, _) = makeTrigger()
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        source.emit(WindowFocus(app: AppInfo(bundleID: "b", name: "A", pid: 1),
                                windowID: 2, title: "t", documentPath: "/nope/gone.txt"))

        guard case .appFocus(let d) = captured[0] else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.documentPath, "/nope/gone.txt")
        XCTAssertNil(d.documentSize)
        XCTAssertNil(d.documentModifiedAt)
    }

    func testAnEmptyTitleBecomesNilRatherThanAnEmptyString() throws {
        // The AX adapter returns "" when a window exposes no title; storing ""
        // and NULL for the same fact would make queries lie.
        let (t, source, _) = makeTrigger()
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        source.emit(WindowFocus(app: AppInfo(bundleID: "b", name: "A", pid: 1),
                                windowID: 0, title: "", documentPath: nil))

        guard case .appFocus(let d) = captured[0] else { return XCTFail("wrong detail kind") }
        XCTAssertNil(d.windowTitle)
        XCTAssertNil(d.windowID, "windowID 0 is the adapter's 'unknown', not a real window")
    }

    func testABrowserURLIsRecordedWithoutBeingTreatedAsAFile() throws {
        // The metadata reader is scripted empty, so a URL that reached the
        // document-metadata path would show up as a filesystem lookup that
        // returned nothing — and, worse, as a `document_path`.
        let (t, source, _) = makeTrigger()
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        source.emit(WindowFocus(app: AppInfo(bundleID: "com.brave.Browser", name: "Brave", pid: 3),
                                windowID: 4, title: "Overview", documentPath: nil,
                                url: "https://example.org/overview"))

        guard case .appFocus(let d) = captured[0] else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.url, "https://example.org/overview")
        XCTAssertNil(d.documentPath, "a page is not a file")
        XCTAssertNil(d.documentSize)
        XCTAssertNil(d.documentType)
    }

    /// Navigating within one window changes neither the window id nor,
    /// necessarily, the title — a site whose tabs share a title would
    /// otherwise read as a single unbroken visit.
    func testANewPageInTheSameWindowIsANewEvent() throws {
        let (t, source, _) = makeTrigger()
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        let app = AppInfo(bundleID: "com.brave.Browser", name: "Brave", pid: 3)
        source.emit(WindowFocus(app: app, windowID: 4, title: "Docs", documentPath: nil,
                                url: "https://example.org/a"))
        source.emit(WindowFocus(app: app, windowID: 4, title: "Docs", documentPath: nil,
                                url: "https://example.org/b"))
        source.emit(WindowFocus(app: app, windowID: 4, title: "Docs", documentPath: nil,
                                url: "https://example.org/b"))

        XCTAssertEqual(captured.count, 2, "two pages, and the repeat of the second is deduplicated")
    }

    /// I-3: a browser tab switch retitles the frontmost window without
    /// activating any application, so `NSWorkspace
    /// .didActivateApplicationNotification` never fires. Without the
    /// title-change nudge the `app_focus` trigger sees nothing at all.
    func testATitleChangeReEmitsFocusAsAnAppFocusEvent() throws {
        let source = FakeFocusSource()
        source.current = WindowFocus(app: AppInfo(bundleID: "com.apple.Safari", name: "Safari", pid: 7),
                                     windowID: 3, title: "Tab Two", documentPath: nil)
        let windows = FakeWindowSource()
        let t = AppFocusTrigger(source: source, titleSource: windows,
                                metadata: ScriptedMetadata(byPath: [:]),
                                executablePath: { _ in nil },
                                now: { Date(timeIntervalSince1970: 7_000) })
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }

        try t.start()
        XCTAssertEqual(windows.startCount, 1, "the nudge only fires while the source observes")
        XCTAssertEqual(captured.count, 1, "start() records what is already frontmost")

        // A retitle with nothing else changed: the poll re-reads the same
        // window, so the dedupe must swallow it. `onTitleChange` fires for
        // every window on the machine, so without this it is the log's single
        // largest source of rows.
        windows.emitTitleChange()
        XCTAssertEqual(captured.count, 1, "an unchanged re-read must not be written again")

        // The real thing: the tab switch that retitled the window.
        source.current = WindowFocus(app: AppInfo(bundleID: "com.apple.Safari", name: "Safari", pid: 7),
                                     windowID: 3, title: "Tab Three", documentPath: nil)
        windows.emitTitleChange()
        XCTAssertEqual(captured.count, 2)
        // `.last`, not `[1]`: when this assertion goes red the array is short,
        // and subscripting it would trap and take the whole test bundle down
        // with it instead of reporting one failed test.
        guard case .appFocus(let d)? = captured.last else { return XCTFail("no app_focus event") }
        XCTAssertEqual(d.windowTitle, "Tab Three")
        XCTAssertEqual(d.bundleID, "com.apple.Safari")
    }

    func testStopEndsTheTitleChangeNudgeToo() throws {
        let source = FakeFocusSource()
        source.current = WindowFocus(app: AppInfo(bundleID: "b", name: "A", pid: 1),
                                     windowID: 1, title: "t", documentPath: nil)
        let windows = FakeWindowSource()
        let t = AppFocusTrigger(source: source, titleSource: windows,
                                metadata: ScriptedMetadata(byPath: [:]),
                                executablePath: { _ in nil })
        var count = 0
        t.onEvent = { _, _ in count += 1 }

        try t.start()
        XCTAssertEqual(count, 1, "start() records the opening focus")
        t.stop()
        XCTAssertEqual(windows.stopCount, 1)
        source.current = WindowFocus(app: AppInfo(bundleID: "b", name: "A", pid: 1),
                                     windowID: 1, title: "changed", documentPath: nil)
        windows.emitTitleChange()
        XCTAssertEqual(count, 1, "a nudge after stop must produce nothing")
    }

    /// The stop guard that keeps `SharedWindowLifecycleSource`'s counted
    /// start/stop balanced: a `stop()` on a trigger that never started must
    /// not decrement an observation a sibling trigger is still using.
    func testStopBeforeStartDoesNotTouchTheTitleSource() {
        let windows = FakeWindowSource()
        let t = AppFocusTrigger(source: FakeFocusSource(), titleSource: windows,
                                metadata: ScriptedMetadata(byPath: [:]),
                                executablePath: { _ in nil })
        t.stop()
        XCTAssertEqual(windows.stopCount, 0)
    }

    func testStopEndsEmission() throws {
        let (t, source, _) = makeTrigger()
        var count = 0
        t.onEvent = { _, _ in count += 1 }
        try t.start()
        source.emit(WindowFocus(app: AppInfo(bundleID: "b", name: "A", pid: 1),
                                windowID: 1, title: "t", documentPath: nil))
        t.stop()
        source.emit(WindowFocus(app: AppInfo(bundleID: "b", name: "A", pid: 1),
                                windowID: 1, title: "t", documentPath: nil))
        XCTAssertEqual(count, 1)
    }

    func testFileReaderReadsARealFile() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("olylo-doc-\(UUID().uuidString).swift")
        try Data("let x = 1\n".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let m = try XCTUnwrap(FileDocumentMetadataReader().metadata(forPath: url.path))
        XCTAssertEqual(m.size, 10)
        XCTAssertNotNil(m.modifiedAt)
        XCTAssertEqual(m.type, "public.swift-source")
        XCTAssertNil(FileDocumentMetadataReader().metadata(forPath: "/definitely/not/here"))
    }

    /// Pins the two filesystem behaviours the reader's doc comment claims. The
    /// symlink half is not theoretical: `attributesOfItem` does not traverse
    /// links, so without the explicit `resolvingSymlinksInPath()` this reports
    /// the link's own size — the byte length of its destination path — as the
    /// document's size.
    func testFileReaderFollowsSymlinksAndTolerantlyHandlesDirectories() throws {
        let fm = FileManager.default
        let target = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("olylo-target-\(UUID().uuidString).swift")
        let link = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("olylo-link-\(UUID().uuidString).swift")
        try Data("let x = 1\n".utf8).write(to: target)
        try fm.createSymbolicLink(at: link, withDestinationURL: target)
        defer {
            try? fm.removeItem(at: link)
            try? fm.removeItem(at: target)
        }

        // The symlink's own size is the length of its destination path, which
        // is nowhere near 10 — so this fails if the reader ever stops following.
        let viaLink = try XCTUnwrap(FileDocumentMetadataReader().metadata(forPath: link.path))
        XCTAssertEqual(viaLink.size, 10, "symlinks must report the target's size")

        // A directory is readable, so it yields metadata rather than nil; the
        // trigger records the focus event either way.
        let dir = try XCTUnwrap(FileDocumentMetadataReader().metadata(forPath: NSTemporaryDirectory()))
        XCTAssertNotNil(dir.modifiedAt)
    }
}
#endif
