#if os(macOS)
import XCTest
import ApplicationServices
@testable import AgenticToolkitActivity

/// Every element the focus read touches gets the messaging timeout before the
/// first call that messages its app. The timeout is per element and is not
/// inherited by a window or child copied out of another, so bounding only the
/// application element left every later read at AX's six-second default.
final class BoundedAXTests: XCTestCase {

    func testEveryElementOfAFocusReadIsBoundedBeforeItIsRead() {
        let tree = FakeAXTree()
        let reading = FrontmostFocusAdapter.focusedWindow(
            pid: tree.appPID, bundleID: "com.apple.Safari", ax: tree.ax, windowID: { _ in 7 })

        XCTAssertEqual(reading.title, "Docs")
        XCTAssertEqual(reading.url, "https://example.com/a")
        XCTAssertEqual(tree.ledger.unboundedReads, [], "an element was read before its timeout was set")
        XCTAssertTrue(tree.ledger.read.contains(tree.window), "the window was read")
        XCTAssertTrue(tree.ledger.read.contains(tree.focused), "the focused element was read")
        XCTAssertTrue(tree.ledger.read.contains(tree.field), "a browser-walk child was read")
        XCTAssertEqual(Set(tree.ledger.timeouts), [BoundedAX.timeout])
    }

    func testAnOffTypeElementAttributeIsNilAndUnbounded() {
        let ledger = Ledger()
        let app = AXUIElementCreateApplication(91_001)
        let ax = BoundedAX(
            setTimeout: { element, seconds in ledger.bound(element, seconds); return .success },
            copy: { _, _ in (.success, "not an element" as CFString) })
        let (status, element) = ax.element(ax.bound(app), kAXFocusedWindowAttribute)
        XCTAssertEqual(status, .success)
        XCTAssertNil(element)
    }
}

/// Records which elements were bounded, and every read made of an element
/// that was not yet.
private final class Ledger: @unchecked Sendable {
    private(set) var boundElements: [AXUIElement] = []
    private(set) var timeouts: [Float] = []
    private(set) var read: [AXUIElement] = []
    private(set) var unboundedReads: [String] = []

    func bound(_ element: AXUIElement, _ seconds: Float) {
        boundElements.append(element)
        timeouts.append(seconds)
    }

    func didRead(_ element: AXUIElement, _ name: String) {
        read.append(element)
        if !boundElements.contains(where: { CFEqual($0, element) }) { unboundedReads.append(name) }
    }
}

/// A Safari window whose document is unnamed (so the focused element and the
/// address-bar walk are both reached), with a text field one level down.
/// Elements are application elements for pids nobody runs: distinct,
/// comparable tokens that the fake answers for and AX itself is never asked.
private final class FakeAXTree: @unchecked Sendable {
    let appPID: pid_t = 91_000
    let app = AXUIElementCreateApplication(91_000)
    let window = AXUIElementCreateApplication(91_001)
    let focused = AXUIElementCreateApplication(91_002)
    let group = AXUIElementCreateApplication(91_003)
    let field = AXUIElementCreateApplication(91_004)
    let ledger = Ledger()

    var ax: BoundedAX {
        BoundedAX(
            setTimeout: { [ledger] element, seconds in ledger.bound(element, seconds); return .success },
            copy: { [self] element, name in
                ledger.didRead(element, name)
                return answer(element, name)
            })
    }

    private func answer(_ element: AXUIElement, _ name: String) -> (AXError, CFTypeRef?) {
        func `is`(_ other: AXUIElement) -> Bool { CFEqual(element, other) }
        switch name {
        case kAXFocusedWindowAttribute where `is`(app): return (.success, window)
        case kAXFocusedUIElementAttribute where `is`(app): return (.success, focused)
        case kAXTitleAttribute where `is`(window): return (.success, "Docs" as CFString)
        case kAXRoleAttribute where `is`(window): return (.success, kAXWindowRole as CFString)
        case kAXRoleAttribute where `is`(group): return (.success, kAXGroupRole as CFString)
        case kAXRoleAttribute where `is`(field): return (.success, kAXTextFieldRole as CFString)
        case "AXIdentifier" where `is`(field):
            return (.success, "WEB_BROWSER_ADDRESS_AND_SEARCH_FIELD" as CFString)
        case kAXValueAttribute where `is`(field): return (.success, "https://example.com/a" as CFString)
        case kAXChildrenAttribute where `is`(window): return (.success, [group] as CFArray)
        case kAXChildrenAttribute where `is`(group): return (.success, [field] as CFArray)
        default: return (.noValue, nil)
        }
    }
}
#endif
