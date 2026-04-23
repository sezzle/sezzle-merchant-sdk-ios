import XCTest
@testable import SezzleMerchantSDK

final class URLParsingTests: XCTestCase {

    // Test callback URL parsing logic by extracting the host+path pattern
    // that CheckoutHandler uses internally.

    func testConfirmedURL_parsesCorrectly() {
        let url = URL(string: "sezzle-sdk://checkout/confirmed")!
        XCTAssertEqual(url.scheme, "sezzle-sdk")
        XCTAssertEqual(url.host, "checkout")
        XCTAssertEqual(url.pathComponents.last, "confirmed")
    }

    func testCancelledURL_parsesCorrectly() {
        let url = URL(string: "sezzle-sdk://checkout/cancelled")!
        XCTAssertEqual(url.scheme, "sezzle-sdk")
        XCTAssertEqual(url.host, "checkout")
        XCTAssertEqual(url.pathComponents.last, "cancelled")
    }

    func testCallbackScheme_isCorrect() {
        XCTAssertEqual(CheckoutHandler.callbackScheme, "sezzle-sdk")
    }

    func testUnexpectedHost_isNotCheckout() {
        let url = URL(string: "sezzle-sdk://unknown/confirmed")!
        XCTAssertNotEqual(url.host, "checkout")
    }

    func testUnexpectedPath_isNotConfirmedOrCancelled() {
        let url = URL(string: "sezzle-sdk://checkout/error")!
        XCTAssertEqual(url.host, "checkout")
        XCTAssertNotEqual(url.pathComponents.last, "confirmed")
        XCTAssertNotEqual(url.pathComponents.last, "cancelled")
    }

    func testMalformedURL_noHost() {
        // URL with just scheme
        let url = URL(string: "sezzle-sdk:///confirmed")!
        XCTAssertTrue(url.host == nil || url.host == "")
    }
}
