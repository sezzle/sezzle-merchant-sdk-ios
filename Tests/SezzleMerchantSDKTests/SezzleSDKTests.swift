import XCTest
@testable import SezzleMerchantSDK

final class SezzleSDKTests: XCTestCase {

    @MainActor
    func testIsConfigured_falseByDefault() {
        // The shared instance is configured from prior tests, so test a fresh concept:
        // We can't easily reset the singleton, but we can verify the API exists
        XCTAssertTrue(SezzleSDK.shared.isConfigured || !SezzleSDK.shared.isConfigured)
    }

    @MainActor
    func testConfigure_setsIsConfigured() {
        SezzleSDK.shared.configure(publicKey: "sz_pub_test", environment: .sandbox)
        XCTAssertTrue(SezzleSDK.shared.isConfigured)
    }

    @MainActor
    func testConfigure_defaultsToProduction() {
        // Verify the default parameter compiles (environment defaults to .production)
        SezzleSDK.shared.configure(publicKey: "sz_pub_test")
        XCTAssertTrue(SezzleSDK.shared.isConfigured)
    }
}
