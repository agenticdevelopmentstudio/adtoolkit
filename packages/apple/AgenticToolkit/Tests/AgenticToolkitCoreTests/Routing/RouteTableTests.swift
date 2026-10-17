import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite("RouteTable")
struct RouteTableTests {

    private func request(_ method: String = "GET", _ path: String = "/a") -> RouteRequest {
        RouteRequest(method: method, path: path)
    }

    private func reply(_ status: Int) -> RouteResponse {
        RouteResponse(status: status, body: Data())
    }

    private let decline: RouteTable.Handler = { _ in nil }

    @Test func theFirstNonNilHandlerWins() async {
        let table = RouteTable([
            decline,
            { _ in RouteResponse(status: 201, body: Data()) },
            { _ in RouteResponse(status: 202, body: Data()) }
        ])

        let response = await table.handle(request())

        #expect(response?.status == 201)
    }

    @Test func aTableThatClaimsNothingReturnsNil() async {
        let table = RouteTable([decline, decline])

        #expect(await table.handle(request()) == nil)
        #expect(await RouteTable().handle(request()) == nil)
    }

    @Test func mergingTriesSelfBeforeOther() async {
        let first = RouteTable([{ _ in RouteResponse(status: 201, body: Data()) }])
        let second = RouteTable([{ _ in RouteResponse(status: 202, body: Data()) }])

        #expect(await first.merging(second).handle(request())?.status == 201)
        #expect(await second.merging(first).handle(request())?.status == 202)
    }

    @Test func mergingFallsThroughToOtherWhenSelfDeclines() async {
        let first = RouteTable([decline])
        let second = RouteTable([{ _ in RouteResponse(status: 202, body: Data()) }])

        #expect(await first.merging(second).handle(request())?.status == 202)
    }

    @Test func exactClaimsOnlyItsMethodAndPath() async {
        let table = RouteTable([
            RouteTable.exact("GET", ["a"]) { _ in RouteResponse(status: 200, body: Data()) }
        ])

        #expect(await table.handle(request("GET", "/a"))?.status == 200)
        #expect(await table.handle(request("POST", "/a")) == nil)
        #expect(await table.handle(request("GET", "/a/b")) == nil)
        #expect(await table.handle(request("GET", "/")) == nil)
    }
}
