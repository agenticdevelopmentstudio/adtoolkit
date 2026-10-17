import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite("RouteResponse")
struct RouteResponseTests {

    private struct Sample: Encodable {
        let fooBar: Int
        let at: Date
    }

    private struct Unencodable: Encodable {
        struct Failure: Error {}
        func encode(to encoder: Encoder) throws { throw Failure() }
    }

    /// 2026-01-31T00:00:00Z.
    private let fixedDate = Date(timeIntervalSince1970: 1_769_817_600)

    @Test func jsonUsesSnakeCaseIsoDatesPrettyPrintingAndSortedKeys() {
        let response = RouteResponse.json(Sample(fooBar: 1, at: fixedDate))

        let expected = "{\n  \"at\" : \"2026-01-31T00:00:00Z\",\n  \"foo_bar\" : 1\n}"
        #expect(String(data: response.body, encoding: .utf8) == expected)
        #expect(response.status == 200)
        #expect(response.contentType == "application/json")
    }

    @Test func jsonCarriesTheRequestedStatus() {
        #expect(RouteResponse.json(Sample(fooBar: 1, at: fixedDate), status: 201).status == 201)
    }

    @Test func aValueThatFailsToEncodeYieldsAnEmptyObject() {
        let response = RouteResponse.json(Unencodable())

        #expect(String(data: response.body, encoding: .utf8) == "{}")
    }

    @Test func errorBodyIsValidJSONThatDecodesBackToTheMessage() throws {
        let message = "a \"quoted\" msg\nwith a newline and a \\ backslash"

        let response = RouteResponse.error(message, status: 400)

        #expect(response.status == 400)
        let object = try #require(JSONSerialization.jsonObject(with: response.body) as? [String: String])
        #expect(object["error"] == message)
    }

    @Test func notFoundIs404() {
        let response = RouteResponse.notFound()

        #expect(response.status == 404)
        #expect(String(data: response.body, encoding: .utf8)?.contains("Not found") == true)
    }

    @Test func noContentIs204WithAnEmptyBody() {
        #expect(RouteResponse.noContent.status == 204)
        #expect(RouteResponse.noContent.body.isEmpty)
        #expect(RouteResponse.noContent.contentType == "application/json")
    }
}
