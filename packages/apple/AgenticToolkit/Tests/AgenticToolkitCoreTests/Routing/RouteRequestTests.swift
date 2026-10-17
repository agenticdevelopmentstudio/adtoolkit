import Foundation
import Testing
@testable import AgenticToolkitCore

/// Guards the `?limit=` / `?offset=` bounds every paging endpoint routes through.
///
/// The bug these exist for: `min(limit, 500)` reads like a clamp but only bounds
/// one end, and SQLite treats a negative `LIMIT` as *no limit* — so `?limit=-1`
/// turned a 500-row page into the whole table, materialised once as DTOs and
/// again as JSON. Four handlers had no bound at all. Both directions are asserted
/// here because only bounding the top is exactly what was wrong before.
@Suite("RouteRequest")
struct RouteRequestTests {

    private func request(_ query: [String: [String]] = [:], path: String = "/events") -> RouteRequest {
        RouteRequest(method: "GET", path: path, queryValues: query)
    }

    // MARK: - Accessors

    @Test func pathComponentsDropEmptySegments() {
        #expect(request(path: "//sessions//abc/").pathComponents == ["sessions", "abc"])
        #expect(request(path: "/").pathComponents.isEmpty)
    }

    @Test func queryReturnsTheLastOfRepeatedValues() {
        #expect(request(["a": ["1", "2", "3"]]).query("a") == "3")
        #expect(request().query("a") == nil)
    }

    @Test func queryAllKeepsWireOrder() {
        #expect(request(["a": ["z", "b", "m"]]).queryAll("a") == ["z", "b", "m"])
        #expect(request().queryAll("a").isEmpty)
    }

    @Test func queryIntFallsBackToTheDefault() {
        #expect(request(["n": ["12"]]).queryInt("n", default: 5) == 12)
        #expect(request(["n": ["x"]]).queryInt("n", default: 5) == 5)
        #expect(request().queryInt("n") == 0)
    }

    // MARK: - limit

    @Test func missingLimitUsesTheDefault() {
        #expect(request().boundedLimit(default: 50, max: 500) == 50)
    }

    @Test func limitInRangeIsHonoured() {
        #expect(request(["limit": ["120"]]).boundedLimit(default: 50, max: 500) == 120)
    }

    @Test func limitAboveTheCeilingIsCappedAtIt() {
        #expect(request(["limit": ["99999"]]).boundedLimit(default: 50, max: 500) == 500)
    }

    @Test func negativeLimitIsRaisedToOneRatherThanMeaningUnlimited() {
        // The whole point: `LIMIT -1` is SQLite for "every row".
        #expect(request(["limit": ["-1"]]).boundedLimit(default: 50, max: 500) == 1)
    }

    @Test func zeroLimitIsRaisedToOne() {
        // `LIMIT 0` is a well-defined empty page, but a caller asking for zero rows
        // is asking for nothing at all; one row keeps every response shape uniform.
        #expect(request(["limit": ["0"]]).boundedLimit(default: 50, max: 500) == 1)
    }

    @Test func unparseableLimitFallsBackToTheDefault() {
        #expect(request(["limit": ["all"]]).boundedLimit(default: 50, max: 500) == 50)
    }

    @Test func anAbsurdDefaultStillCannotExceedItsOwnCeiling() {
        // Guards the `/insights/daily-metrics` shape, where the default is large.
        #expect(request().boundedLimit(default: 20_000, max: 10_000) == 10_000)
    }

    // MARK: - offset

    @Test func missingOffsetIsZero() {
        #expect(request().boundedOffset() == 0)
    }

    @Test func offsetInRangeIsHonoured() {
        #expect(request(["offset": ["250"]]).boundedOffset() == 250)
    }

    @Test func negativeOffsetIsFlooredAtZero() {
        #expect(request(["offset": ["-40"]]).boundedOffset() == 0)
    }

    // MARK: - since / until

    // `validatedTimestamp` is the other half of the same lesson: a bad bound
    // that gets *clamped* is a wrong page, but a bad bound that reaches a
    // lexicographic `timestamp >= ?` is a wrong answer served as HTTP 200.

    @Test func aMissingTimestampMeansAnUnboundedWindow() {
        #expect(request().validatedTimestamp("since") == .success(nil))
    }

    @Test func anEmptyTimestampMeansAnUnboundedWindow() {
        // `?since=` is what a UI sends when its date field is cleared; it is a
        // request for everything, not a malformed request.
        #expect(request(["since": [""]]).validatedTimestamp("since") == .success(nil))
    }

    @Test func aWholeSecondBoundIsNormalisedToFractionalSeconds() {
        // The stored timestamps carry milliseconds, and `'Z' > '.'` bytewise,
        // so the un-normalised form of this bound excludes the first second of
        // its own range.
        #expect(request(["since": ["2026-01-31T00:00:00Z"]]).validatedTimestamp("since")
                == .success("2026-01-31T00:00:00.000Z"))
    }

    @Test func aFractionalBoundSurvivesUnchanged() {
        #expect(request(["since": ["2026-01-31T00:00:00.500Z"]]).validatedTimestamp("since")
                == .success("2026-01-31T00:00:00.500Z"))
    }

    @Test func anOffsetBoundIsRebasedOntoUTC() {
        // Every stored timestamp is UTC, so a `+02:00` bound compared as a
        // string would be two hours off in the wrong direction.
        #expect(request(["since": ["2026-01-31T02:00:00+02:00"]]).validatedTimestamp("since")
                == .success("2026-01-31T00:00:00.000Z"))
    }

    @Test func aWordIsRejectedRatherThanSortingAboveEveryRealTimestamp() {
        // `'y' > '2'`, so `?since=yesterday` used to return a confidently empty
        // result instead of an error.
        guard case .failure(let invalid) = request(["since": ["yesterday"]]).validatedTimestamp("since") else {
            Issue.record("`yesterday` must not be accepted as a timestamp")
            return
        }
        #expect(invalid.message.contains("since"))
        #expect(invalid.message.contains("yesterday"))
    }

    @Test func aBareYearIsRejectedRatherThanSilentlyMeaningEverything() {
        // The dangerous direction: `'2026' < '2026-…'`, so this one used to
        // widen the window to the whole table while looking deliberate.
        guard case .failure = request(["since": ["2026"]]).validatedTimestamp("since") else {
            Issue.record("a bare year must not be accepted as a timestamp")
            return
        }
    }

    @Test func theRejectionNamesTheParameterThatWasWrong() {
        // `/insights/active-hours` validates two bounds; an error that didn't
        // say which one leaves the caller guessing.
        guard case .failure(let invalid) = request(["until": ["nope"]]).validatedTimestamp("until") else {
            Issue.record("`nope` must not be accepted as a timestamp")
            return
        }
        #expect(invalid.message.contains("until"))
    }

    // MARK: - activitySince

    @Test func activitySinceTruncatesToWholeSeconds() {
        #expect(RouteRequest.activitySince("2026-10-03T11:00:00.500Z") == .success("2026-10-03T11:00:00Z"))
    }

    @Test func activitySinceTreatsNilAndEmptyAsNoBound() {
        #expect(RouteRequest.activitySince(nil) == .success(""))
        #expect(RouteRequest.activitySince("") == .success(""))
    }

    /// No caller ever named the parameter, so `activitySince` takes none — its one
    /// type is `(String?) -> Result` — and its refusal names `since`.
    @Test func activitySinceTakesOnlyTheTextAndItsRefusalNamesSince() {
        let parse: (String?) -> Result<String, InvalidTimestamp> = RouteRequest.activitySince
        guard case .failure(let refusal) = parse("yesterday") else {
            Issue.record("a word is not a timestamp")
            return
        }
        #expect(refusal.message.contains("`since`"))
    }

    /// The daemon's `since` and Core's validator — the one a CLI checks `--since`
    /// with — accept exactly the same strings.
    @Test func activitySinceAcceptsExactlyWhatCoreAccepts() {
        let inputs = ["2026-10-01T00:00:00Z", "2026-10-01T00:00:00.250Z", "2026-10-01T02:00:00+02:00",
                      "2026-10-01 00:00:00", "2026-10-01", "yesterday", "2026", "2026-13-01T00:00:00Z"]
        for text in inputs {
            let accepted: Bool
            if case .success = RouteRequest.activitySince(text) { accepted = true } else { accepted = false }
            #expect(accepted == (TimestampParsing.parseISO8601(text) != nil), "\(text)")
        }
    }
}
