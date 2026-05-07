import XCTest
@testable import SezzleMerchantSDK

final class CheckoutHandlerMatchTests: XCTestCase {

    func testMatch_exactCustomScheme() {
        let target = URL(string: "sezzle-sdk://checkout/confirmed")!
        let url = URL(string: "sezzle-sdk://checkout/confirmed")!
        XCTAssertTrue(CheckoutHandler.matches(url, target: target))
    }

    func testMatch_extraQueryParamsStillMatch() {
        let target = URL(string: "poshmark-sezzle://checkout/done")!
        let url = URL(string: "poshmark-sezzle://checkout/done?orderRef=12345&extra=true")!
        XCTAssertTrue(CheckoutHandler.matches(url, target: target))
    }

    func testMatch_caseInsensitiveSchemeAndHost() {
        let target = URL(string: "Poshmark-Sezzle://Checkout/done")!
        let url = URL(string: "poshmark-sezzle://checkout/done")!
        XCTAssertTrue(CheckoutHandler.matches(url, target: target))
    }

    func testMatch_differentPathDoesNotMatch() {
        let target = URL(string: "sezzle-sdk://checkout/confirmed")!
        let url = URL(string: "sezzle-sdk://checkout/cancelled")!
        XCTAssertFalse(CheckoutHandler.matches(url, target: target))
    }

    func testMatch_differentSchemeDoesNotMatch() {
        let target = URL(string: "sezzle-sdk://checkout/confirmed")!
        let url = URL(string: "other-sdk://checkout/confirmed")!
        XCTAssertFalse(CheckoutHandler.matches(url, target: target))
    }

    func testMatch_httpsURLsWork() {
        let target = URL(string: "https://merchant.com/checkout/done")!
        let url = URL(string: "https://merchant.com/checkout/done?orderRef=42")!
        XCTAssertTrue(CheckoutHandler.matches(url, target: target))
    }

    func testMatch_httpsDifferentDomainDoesNotMatch() {
        let target = URL(string: "https://merchant.com/checkout/done")!
        let url = URL(string: "https://attacker.com/checkout/done")!
        XCTAssertFalse(CheckoutHandler.matches(url, target: target))
    }

    func testMatch_pathOnlySchemeURL() {
        let target = URL(string: "myapp://done")!
        let url = URL(string: "myapp://done?id=1")!
        XCTAssertTrue(CheckoutHandler.matches(url, target: target))
    }
}
