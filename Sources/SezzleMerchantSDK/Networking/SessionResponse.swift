import Foundation

/// The JSON response from `POST /v2/session`.
struct SessionResponse: Decodable, Sendable {
    let uuid: String
    let order: OrderResponse

    struct OrderResponse: Decodable, Sendable {
        let uuid: String
        let checkoutURL: String

        enum CodingKeys: String, CodingKey {
            case uuid
            case checkoutURL = "checkout_url"
        }
    }
}
