import XCTest
@testable import SezzleMerchantSDK

final class SezzleCheckoutResultTests: XCTestCase {

    func testInit_sdkCreatesSessionFlow() {
        let result = SezzleCheckoutResult(orderUUID: "ord-123")
        XCTAssertEqual(result.orderUUID, "ord-123")
        XCTAssertNil(result.callbackURL)
    }

    func testInit_serverDrivenFlow() {
        let url = URL(string: "poshmark-sezzle://checkout/done?orderRef=12345")!
        let result = SezzleCheckoutResult(callbackURL: url)
        XCTAssertNil(result.orderUUID)
        XCTAssertEqual(result.callbackURL, url)
    }

    func testInit_defaultsBothNil() {
        let result = SezzleCheckoutResult()
        XCTAssertNil(result.orderUUID)
        XCTAssertNil(result.callbackURL)
    }

    func testCallbackURL_queryParamsAccessible() {
        let url = URL(string: "poshmark-sezzle://checkout/done?orderRef=12345&promo=summer")!
        let result = SezzleCheckoutResult(callbackURL: url)

        let components = URLComponents(url: result.callbackURL!, resolvingAgainstBaseURL: false)!
        let orderRef = components.queryItems?.first(where: { $0.name == "orderRef" })?.value
        let promo = components.queryItems?.first(where: { $0.name == "promo" })?.value

        XCTAssertEqual(orderRef, "12345")
        XCTAssertEqual(promo, "summer")
    }
}
