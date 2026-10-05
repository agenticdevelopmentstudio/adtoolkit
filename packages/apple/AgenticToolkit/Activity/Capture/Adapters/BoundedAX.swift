// Accessibility attribute reads with a bounded messaging timeout — macOS only (c2).
#if os(macOS)
import ApplicationServices

/// The one way the focus readers read an Accessibility attribute: every
/// element is given the messaging timeout before the first call that messages
/// its app.
///
/// `AXUIElementSetMessagingTimeout` is per element, and an element copied out
/// of another (a window out of its app, a child out of a window) does not
/// inherit it. Setting it only on the application element left the window,
/// the focused element and every element of a browser walk at AX's six-second
/// default, so a hung frontmost app stalled the main actor for six seconds per
/// read. Every element this hands back is already bounded.
struct BoundedAX: Sendable {
    /// How long one attribute read may wait on the target app.
    static let timeout: Float = 1.0

    /// `AXUIElementSetMessagingTimeout`.
    let setTimeout: @Sendable (AXUIElement, Float) -> AXError
    /// `AXUIElementCopyAttributeValue`, as the error and the value.
    let copy: @Sendable (AXUIElement, String) -> (AXError, CFTypeRef?)

    static let live = BoundedAX(
        setTimeout: { AXUIElementSetMessagingTimeout($0, $1) },
        copy: { element, name in
            var value: CFTypeRef?
            let error = AXUIElementCopyAttributeValue(element, name as CFString, &value)
            return (error, value)
        })

    /// `element`, with its timeout set. Call it on an element this type did not
    /// hand out (the one made from a pid) before reading from it.
    @discardableResult
    func bound(_ element: AXUIElement) -> AXUIElement {
        _ = setTimeout(element, Self.timeout)
        return element
    }

    /// A value attribute of an element that is already bounded.
    func attribute(_ element: AXUIElement, _ name: String) -> (AXError, CFTypeRef?) {
        copy(element, name)
    }

    /// An element-valued attribute, type-checked and bounded before it is
    /// returned. A value of another CF type is a soft nil, never a trap.
    func element(_ element: AXUIElement, _ name: String) -> (AXError, AXUIElement?) {
        let (error, value) = copy(element, name)
        guard error == .success, let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return (error, nil)
        }
        return (error, bound(value as! AXUIElement))   // swiftlint:disable:this force_cast
    }

    /// The element's children, each bounded.
    func children(_ element: AXUIElement) -> [AXUIElement] {
        let (error, value) = copy(element, kAXChildrenAttribute)
        guard error == .success, let children = value as? [AXUIElement] else { return [] }
        return children.map { bound($0) }
    }
}
#endif
