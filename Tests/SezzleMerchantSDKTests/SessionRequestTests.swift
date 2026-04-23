import XCTest
@testable import SezzleMerchantSDK

final class SessionRequestTests: XCTestCase {

    func testEncoding_matchesAPIContract() throws {
        let checkout = SezzleCheckout(
            customer: SezzleCustomer(
                email: "jane@example.com",
                firstName: "Jane",
                lastName: "Doe"
            ),
            order: SezzleOrder(
                referenceId: "ord-123",
                description: "Test order",
                amount: SezzleAmount(amountInCents: 4999, currency: "USD"),
                items: [
                    SezzleItem(
                        name: "Widget",
                        sku: "sku-1",
                        quantity: 1,
                        price: SezzleAmount(amountInCents: 4999, currency: "USD")
                    )
                ]
            )
        )

        let request = SessionRequest.from(checkout)
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Top-level keys use snake_case
        XCTAssertNotNil(json["cancel_url"])
        XCTAssertNotNil(json["complete_url"])
        XCTAssertNotNil(json["order"])
        XCTAssertNotNil(json["customer"])

        // cancel_url and complete_url use sezzle-sdk:// scheme
        let cancelURL = json["cancel_url"] as! [String: Any]
        XCTAssertEqual(cancelURL["href"] as? String, "sezzle-sdk://checkout/cancelled")
        XCTAssertEqual(cancelURL["method"] as? String, "GET")

        let completeURL = json["complete_url"] as! [String: Any]
        XCTAssertEqual(completeURL["href"] as? String, "sezzle-sdk://checkout/confirmed")

        // Order uses snake_case field names
        let order = json["order"] as! [String: Any]
        XCTAssertEqual(order["intent"] as? String, "AUTH")
        XCTAssertEqual(order["reference_id"] as? String, "ord-123")
        XCTAssertEqual(order["description"] as? String, "Test order")

        let orderAmount = order["order_amount"] as! [String: Any]
        XCTAssertEqual(orderAmount["amount_in_cents"] as? Int, 4999)
        XCTAssertEqual(orderAmount["currency"] as? String, "USD")

        // Items
        let items = order["items"] as! [[String: Any]]
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0]["name"] as? String, "Widget")
        XCTAssertEqual(items[0]["sku"] as? String, "sku-1")
        XCTAssertEqual(items[0]["quantity"] as? Int, 1)

        // Customer uses snake_case
        let customer = json["customer"] as! [String: Any]
        XCTAssertEqual(customer["email"] as? String, "jane@example.com")
        XCTAssertEqual(customer["first_name"] as? String, "Jane")
        XCTAssertEqual(customer["last_name"] as? String, "Doe")
    }

    func testEncoding_intentCapture() throws {
        let checkout = SezzleCheckout(
            customer: SezzleCustomer(email: "test@test.com"),
            order: SezzleOrder(
                referenceId: "ord-456",
                amount: SezzleAmount(amountInCents: 10000, currency: "USD"),
                intent: .capture
            )
        )

        let request = SessionRequest.from(checkout)
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let order = json["order"] as! [String: Any]

        XCTAssertEqual(order["intent"] as? String, "CAPTURE")
    }

    func testEncoding_optionalFieldsOmitted() throws {
        let checkout = SezzleCheckout(
            customer: SezzleCustomer(email: "test@test.com"),
            order: SezzleOrder(
                referenceId: "ord-789",
                amount: SezzleAmount(amountInCents: 5000, currency: "USD")
            )
        )

        let request = SessionRequest.from(checkout)
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let order = json["order"] as! [String: Any]

        // description defaults to "Mobile SDK Order" when not provided
        XCTAssertEqual(order["description"] as? String, "Mobile SDK Order")
        // items should be null/absent when not provided
        XCTAssertTrue(order["items"] is NSNull || order["items"] == nil)

        let customer = json["customer"] as! [String: Any]
        XCTAssertTrue(customer["first_name"] is NSNull || customer["first_name"] == nil)
        XCTAssertTrue(customer["last_name"] is NSNull || customer["last_name"] == nil)
        XCTAssertTrue(customer["phone"] is NSNull || customer["phone"] == nil)
    }
}
