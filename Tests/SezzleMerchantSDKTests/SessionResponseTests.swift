import XCTest
@testable import SezzleMerchantSDK

final class SessionResponseTests: XCTestCase {

    func testDecoding_successResponse() throws {
        let json = """
        {
            "uuid": "session-uuid-123",
            "order": {
                "uuid": "order-uuid-456",
                "checkout_url": "https://checkout.sezzle.com/?id=order-uuid-456"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(SessionResponse.self, from: json)
        XCTAssertEqual(response.uuid, "session-uuid-123")
        XCTAssertEqual(response.order.uuid, "order-uuid-456")
        XCTAssertEqual(response.order.checkoutURL, "https://checkout.sezzle.com/?id=order-uuid-456")
    }

    func testDecoding_missingOrderUUID_throws() {
        let json = """
        {
            "uuid": "session-uuid-123",
            "order": {
                "checkout_url": "https://checkout.sezzle.com/?id=test"
            }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(SessionResponse.self, from: json))
    }

    func testDecoding_missingCheckoutURL_throws() {
        let json = """
        {
            "uuid": "session-uuid-123",
            "order": {
                "uuid": "order-uuid-456"
            }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(SessionResponse.self, from: json))
    }

    func testDecoding_malformedJSON_throws() {
        let json = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(SessionResponse.self, from: json))
    }

    func testDecoding_emptyJSON_throws() {
        let json = "{}".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(SessionResponse.self, from: json))
    }
}
