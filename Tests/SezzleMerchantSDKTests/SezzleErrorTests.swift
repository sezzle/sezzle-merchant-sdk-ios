import XCTest
@testable import SezzleMerchantSDK

final class SezzleErrorTests: XCTestCase {

    func testNotConfigured_hasDescription() {
        let error = SezzleError.notConfigured
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("not configured"))
    }

    func testNetworkError_includesUnderlying() {
        let underlying = URLError(.notConnectedToInternet)
        let error = SezzleError.networkError(underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("network"))
    }

    func testAPIError_includesStatusAndMessage() {
        let error = SezzleError.apiError(statusCode: 401, message: "Unauthorized")
        let description = error.errorDescription!
        XCTAssertTrue(description.contains("401"))
        XCTAssertTrue(description.contains("Unauthorized"))
    }

    func testBrowserDismissed_hasDescription() {
        let error = SezzleError.browserDismissed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("dismissed"))
    }

    func testInvalidResponse_hasDescription() {
        let error = SezzleError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("parse") || error.errorDescription!.lowercased().contains("response"))
    }
}
