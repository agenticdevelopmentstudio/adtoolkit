import CryptoKit
import Foundation
import Testing
@testable import AgenticToolkitCore

struct DigestHexTests {

    @Test func sha256OfAKnownStringIsItsLowercaseHex() {
        #expect(SHA256.hash(data: Data("abc".utf8)).hexString
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
