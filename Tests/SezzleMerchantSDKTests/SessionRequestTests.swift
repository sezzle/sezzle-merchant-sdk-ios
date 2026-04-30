import XCTest
@testable import SezzleMerchantSDK

@MainActor
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

        // SDK metadata is always present
        let metadata = order["metadata"] as! [String: Any]
        XCTAssertEqual(metadata["_sdk_platform"] as? String, "ios")
        XCTAssertNotNil(metadata["_sdk_version"])
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

        // SDK metadata still present even without user metadata
        let metadata = order["metadata"] as! [String: Any]
        XCTAssertEqual(metadata["_sdk_platform"] as? String, "ios")
    }

    func testEncoding_newFields() throws {
        let checkout = SezzleCheckout(
            customer: SezzleCustomer(
                email: "jane@example.com",
                dob: "1990-01-15",
                billingAddress: SezzleAddress(
                    street: "123 Main St",
                    city: "Minneapolis",
                    state: "MN",
                    postalCode: "55401",
                    countryCode: "US"
                )
            ),
            order: SezzleOrder(
                referenceId: "ord-new",
                amount: SezzleAmount(amountInCents: 5000, currency: "USD"),
                discounts: [
                    SezzleDiscount(name: "10OFF", amount: SezzleAmount(amountInCents: 500, currency: "USD"))
                ],
                taxAmount: SezzleAmount(amountInCents: 350, currency: "USD"),
                shippingAmount: SezzleAmount(amountInCents: 250, currency: "USD"),
                metadata: ["campaign": "summer2026"],
                locale: .enUS
            )
        )

        let request = SessionRequest.from(checkout)
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Customer new fields
        let customer = json["customer"] as! [String: Any]
        XCTAssertEqual(customer["dob"] as? String, "1990-01-15")
        let billing = customer["billing_address"] as! [String: Any]
        XCTAssertEqual(billing["street"] as? String, "123 Main St")
        XCTAssertEqual(billing["city"] as? String, "Minneapolis")
        XCTAssertEqual(billing["postal_code"] as? String, "55401")
        XCTAssertEqual(billing["country_code"] as? String, "US")

        // Order new fields
        let order = json["order"] as! [String: Any]
        let discounts = order["discounts"] as! [[String: Any]]
        XCTAssertEqual(discounts.count, 1)
        XCTAssertEqual(discounts[0]["name"] as? String, "10OFF")

        let tax = order["tax_amount"] as! [String: Any]
        XCTAssertEqual(tax["amount_in_cents"] as? Int, 350)

        let shipping = order["shipping_amount"] as! [String: Any]
        XCTAssertEqual(shipping["amount_in_cents"] as? Int, 250)

        XCTAssertEqual(order["locale"] as? String, "en-US")

        // User metadata merged with SDK metadata
        let metadata = order["metadata"] as! [String: Any]
        XCTAssertEqual(metadata["campaign"] as? String, "summer2026")
        XCTAssertEqual(metadata["_sdk_platform"] as? String, "ios")
    }
}
