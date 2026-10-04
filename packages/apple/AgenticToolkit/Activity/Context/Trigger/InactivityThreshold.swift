import Foundation

/// How long the machine must be quiet before ``InputActivityTrigger`` records
/// that the user has gone — the value itself, its limits, and the arithmetic
/// every surface needs to show it.
///
/// One type rather than constants on ``SettingsStore`` because three
/// processes' worth of code needs these numbers and only one of them can see
/// that store: `SettingsStore` is compiled only where
/// `AgenticToolkitDatabase` is available, while the settings panel that edits
/// the value and the trigger that obeys it are neither of them the database
/// layer. Putting the authority here keeps a single representation (DRY) that
/// all three can reach, instead of a default repeated in the trigger, a range
/// repeated in the panel, and a clamp that only the daemon knows about.
///
/// It is also where the seconds↔minutes conversion lives, for the reason
/// every other rule in AgenticToolkitActivity lives here: it is a rule, and a rule in a
/// view controller is a rule no test can reach.
public enum InactivityThreshold {
    /// Three minutes — long enough to read a page of code without being
    /// declared absent, short enough that stepping out for coffee is recorded
    /// as the break it was. It is also what `IdleAdapter` hardcoded before
    /// this became a setting, so an existing install's behaviour does not
    /// change until someone changes it.
    public static let defaultSeconds = 180

    /// Narrower than the trigger's poll interval cannot be honoured; wider
    /// than a day would never fire.
    public static let secondsRange = 30...(24 * 60 * 60)

    /// Enforced on the way in *and* on the way out of the store, so a value
    /// written by an older build, a future one, or by hand cannot make the
    /// trigger stop reporting.
    public static func clamp(seconds: Int) -> Int {
        min(max(seconds, secondsRange.lowerBound), secondsRange.upperBound)
    }

    // MARK: - Minutes, for editing

    /// What a stepper offers, in minutes. Deliberately narrower than
    /// ``secondsRange``: a threshold measured in seconds is a debugging
    /// value, not something to hand a person a stepper for, and two hours is
    /// already far past the point where "away" stops being a useful word.
    ///
    /// A value outside this range is not *invalid* — the store accepts
    /// anything ``secondsRange`` allows, whoever wrote it — it is merely
    /// outside what this control can express, which is why
    /// ``minutes(fromSeconds:)`` clamps for display rather than rejecting.
    public static let minuteRange = 1...120

    /// The nearest whole minute, clamped to what a stepper can show.
    ///
    /// Rounds rather than truncates so a stored 90 seconds reads as 2 minutes
    /// and not as 1. Callers must treat the result as a *display* value and
    /// write it back only when the user actually edits it: 45 seconds shows
    /// as 1 minute, and a panel that echoed its own rounding back to the
    /// store would silently change a setting nobody touched.
    public static func minutes(fromSeconds seconds: Int) -> Int {
        let rounded = Int((Double(seconds) / 60).rounded())
        return min(max(rounded, minuteRange.lowerBound), minuteRange.upperBound)
    }

    public static func seconds(fromMinutes minutes: Int) -> Int {
        clamp(seconds: minutes * 60)
    }
}
