#if os(macOS)
import Foundation
import Security

/// The running process's own code signature, as macOS privacy (TCC) sees it.
public enum OwnCodeSignature {
    /// This process's designated requirement as text, or `nil` when it cannot
    /// be read (an unsigned binary, say).
    ///
    /// TCC records a grant against the designated requirement of the code it
    /// was given to, so two builds share a grant exactly when they share this
    /// string: a rebuild under the same certificate keeps it, a re-sign under
    /// another identity (Apple Development → Developer ID) does not. Reading
    /// it asks only the Security framework about this process's own code — no
    /// TCC or Accessibility call — so it is safe from a process without any
    /// grant.
    public static func designatedRequirement() -> String? {
        var code: SecCode?
        guard SecCodeCopySelf(SecCSFlags(), &code) == errSecSuccess, let code else { return nil }
        // The requirement is read from the static form; see JITAvailability.
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, SecCSFlags(), &staticCode) == errSecSuccess,
              let staticCode
        else { return nil }
        var requirement: SecRequirement?
        guard SecCodeCopyDesignatedRequirement(staticCode, SecCSFlags(), &requirement) == errSecSuccess,
              let requirement
        else { return nil }
        var text: CFString?
        guard SecRequirementCopyString(requirement, SecCSFlags(), &text) == errSecSuccess,
              let text
        else { return nil }
        return text as String
    }
}
#endif
