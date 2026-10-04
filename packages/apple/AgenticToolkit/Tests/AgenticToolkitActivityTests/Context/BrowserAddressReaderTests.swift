#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity

/// The two decisions in `BrowserAddressReader` that do not need a live browser
/// to exercise: which apps get walked at all, and which values are accepted as
/// an address once found. The walk itself is AX plumbing and is covered by the
/// live daemon rather than here.
final class BrowserAddressReaderTests: XCTestCase {
    private typealias Reader = BrowserAddressReader

    func testSafariAndItsPreviewBuildAreRecognised() {
        XCTAssertEqual(Reader.Family.forBundleID("com.apple.Safari"), .safari)
        XCTAssertEqual(Reader.Family.forBundleID("com.apple.SafariTechnologyPreview"), .safari)
    }

    func testEveryShippingFirefoxChannelIsRecognised() {
        for bundle in ["org.mozilla.firefox", "org.mozilla.firefoxdeveloperedition",
                       "org.mozilla.nightly"] {
            XCTAssertEqual(Reader.Family.forBundleID(bundle), .firefox, bundle)
        }
    }

    /// Chromium browsers are the point of this test, not an oversight. They
    /// answer `kAXDocumentAttribute` with the full URL, so walking their view
    /// tree would cost a descent into a rendered page on every focus change
    /// and find nothing the adapter did not already have.
    func testChromiumBrowsersAreNotWalked() {
        for bundle in ["com.google.Chrome", "com.brave.Browser",
                       "com.microsoft.edgemac", "company.thebrowser.Browser"] {
            XCTAssertNil(Reader.Family.forBundleID(bundle), bundle)
        }
    }

    func testANonBrowserIsNotWalked() {
        XCTAssertNil(Reader.Family.forBundleID("com.apple.dt.Xcode"))
        XCTAssertNil(Reader.Family.forBundleID(""))
    }

    func testAnExplicitSchemeIsAnAddress() {
        XCTAssertTrue(Reader.looksLikeAnAddress("https://example.org/page"))
        XCTAssertTrue(Reader.looksLikeAnAddress("http://localhost:3000"))
    }

    /// Firefox reports the address the way it draws it — scheme stripped — so
    /// a reader that insisted on one would record nothing for Firefox at all.
    func testASchemelessHostIsAnAddress() {
        XCTAssertTrue(Reader.looksLikeAnAddress("example.org/spike-check"))
        XCTAssertTrue(Reader.looksLikeAnAddress("news.ycombinator.com"))
    }

    /// Firefox's address bar is matched on its role alone, so this test is the
    /// only thing standing between a half-typed search and a row claiming the
    /// user visited a site.
    func testAHalfTypedSearchIsNotAnAddress() {
        XCTAssertFalse(Reader.looksLikeAnAddress("how to fix a "))
        XCTAssertFalse(Reader.looksLikeAnAddress(""))
        XCTAssertFalse(Reader.looksLikeAnAddress("swift concurrency"))
    }

    func testADotAtEitherEndIsNotAnAddress() {
        XCTAssertFalse(Reader.looksLikeAnAddress(".hidden"))
        XCTAssertFalse(Reader.looksLikeAnAddress("trailing."))
    }
}
#endif
