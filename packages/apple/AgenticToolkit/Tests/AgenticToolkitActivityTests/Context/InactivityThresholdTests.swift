import XCTest
@testable import AgenticToolkitActivity

/// The one authoritative representation of the inactivity threshold. Three
/// callers depend on it — the trigger, the settings store, and the app's
/// settings panel — and they run in two different processes, so a
/// disagreement between them shows up as a number that changes when you look
/// at it.
final class InactivityThresholdTests: XCTestCase {

    func testTheDefaultIsInsideTheRange() {
        XCTAssertTrue(InactivityThreshold.secondsRange.contains(InactivityThreshold.defaultSeconds))
    }

    func testTheDefaultIsNeverZero() {
        // Zero would declare the user absent the instant they stop typing,
        // which is the failure the "unknown is not a number" rule around this
        // setting exists to prevent.
        XCTAssertGreaterThan(InactivityThreshold.defaultSeconds, 0)
    }

    func testClampingHoldsTheEnds() {
        XCTAssertEqual(InactivityThreshold.clamp(seconds: 0),
                       InactivityThreshold.secondsRange.lowerBound)
        XCTAssertEqual(InactivityThreshold.clamp(seconds: -1),
                       InactivityThreshold.secondsRange.lowerBound)
        XCTAssertEqual(InactivityThreshold.clamp(seconds: Int.max),
                       InactivityThreshold.secondsRange.upperBound)
        XCTAssertEqual(InactivityThreshold.clamp(seconds: 600), 600)
    }

    func testMinutesRoundRatherThanTruncate() {
        // 90 seconds is nearer two minutes than one. Truncating would show
        // "1", and a stepper that then wrote its displayed value back would
        // quietly move the user's setting to 60.
        XCTAssertEqual(InactivityThreshold.minutes(fromSeconds: 90), 2)
        XCTAssertEqual(InactivityThreshold.minutes(fromSeconds: 89), 1)
        XCTAssertEqual(InactivityThreshold.minutes(fromSeconds: 300), 5)
    }

    func testMinutesAreClampedToWhatTheStepperCanShow() {
        // The seconds range runs to a full day; the stepper does not. A value
        // outside what the control can represent must land on an end of it
        // rather than out of bounds.
        XCTAssertEqual(
            InactivityThreshold.minutes(fromSeconds: InactivityThreshold.secondsRange.lowerBound),
            InactivityThreshold.minuteRange.lowerBound,
            "30 seconds rounds to half a minute, which the control cannot show")
        XCTAssertEqual(
            InactivityThreshold.minutes(fromSeconds: InactivityThreshold.secondsRange.upperBound),
            InactivityThreshold.minuteRange.upperBound)
    }

    func testSecondsFromMinutesIsClamped() {
        XCTAssertEqual(InactivityThreshold.seconds(fromMinutes: 5), 300)
        XCTAssertEqual(InactivityThreshold.seconds(fromMinutes: 0),
                       InactivityThreshold.secondsRange.lowerBound)
        XCTAssertEqual(InactivityThreshold.seconds(fromMinutes: 100_000),
                       InactivityThreshold.secondsRange.upperBound)
    }

    func testEveryMinuteTheStepperCanShowSurvivesARoundTrip() {
        // The panel writes seconds and reads seconds back, then converts for
        // display. If any position on the stepper came back as a different
        // position, stepping up once and refreshing would move the control
        // somewhere the user did not put it.
        for minutes in InactivityThreshold.minuteRange {
            let seconds = InactivityThreshold.seconds(fromMinutes: minutes)
            XCTAssertEqual(InactivityThreshold.minutes(fromSeconds: seconds), minutes,
                           "\(minutes) minutes did not survive the round trip")
        }
    }
}
