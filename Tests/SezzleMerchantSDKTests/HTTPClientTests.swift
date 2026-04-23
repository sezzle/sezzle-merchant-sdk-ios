import XCTest
@testable import SezzleMerchantSDK

final class HTTPClientTests: XCTestCase {

    // MARK: - Authorization header

    func testAuthorizationHeader_encodesPublicKeyWithoutColon() {
        let client = HTTPClient(publicKey: "sz_pub_test123", environment: .sandbox)
        let expected = "Basic " + Data("sz_pub_test123".utf8).base64EncodedString()
        XCTAssertEqual(client.authorizationHeader, expected)
    }

    func testAuthorizationHeader_emptyKey() {
        let client = HTTPClient(publicKey: "", environment: .sandbox)
        let expected = "Basic " + Data("".utf8).base64EncodedString()
        XCTAssertEqual(client.authorizationHeader, expected)
    }

    // MARK: - Platform header

    func testPlatformHeader_isValidBase64JSON() throws {
        let client = HTTPClient(publicKey: "test", environment: .sandbox)
        let header = client.platformHeader

        // Should be valid base64
        let decoded = try XCTUnwrap(Data(base64Encoded: header))
        let json = try JSONSerialization.jsonObject(with: decoded) as! [String: String]

        // Should have exactly 3 fields
        XCTAssertEqual(json.count, 3)
        XCTAssertEqual(json["id"], "mobile-sdk-ios")
        XCTAssertNotNil(json["version"])
        XCTAssertNotNil(json["plugin_version"])
        XCTAssertEqual(json["version"], json["plugin_version"])
    }

    // MARK: - Environment routing

    func testEnvironment_productionURL() {
        let client = HTTPClient(publicKey: "test", environment: .production)
        XCTAssertEqual(client.environment.gatewayURL.absoluteString, "https://gateway.sezzle.com")
    }

    func testEnvironment_sandboxURL() {
        let client = HTTPClient(publicKey: "test", environment: .sandbox)
        XCTAssertEqual(client.environment.gatewayURL.absoluteString, "https://sandbox.gateway.sezzle.com")
    }
}
