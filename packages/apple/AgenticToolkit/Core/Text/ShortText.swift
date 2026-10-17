import Foundation

extension String {
    /// This text cut to `limit` characters, ending in an ellipsis when it had to
    /// be cut.
    ///
    /// One budget in one place. A quota card gives an error line about sixty
    /// characters before it wraps, and that number had been written out three
    /// separate times — in the refresher, in the evaluator and in the probe — so
    /// tuning any one of them would have left the other two saying something a
    /// different width.
    public func shortened(to limit: Int = 60) -> String {
        count > limit ? String(prefix(limit - 3)) + "…" : self
    }
}
