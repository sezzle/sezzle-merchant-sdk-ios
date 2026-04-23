import Foundation

/// The JSON body sent to `POST /v2/session`.
struct SessionRequest: Encodable, Sendable {
    let cancelURL: URLRef
    let completeURL: URLRef
    let order: OrderPayload
    let customer: CustomerPayload

    struct URLRef: Encodable, Sendable {
        let href: String
        let method: String = "GET"
    }

    struct OrderPayload: Encodable, Sendable {
        let intent: String
        let referenceID: String
        let description: String
        let orderAmount: AmountPayload
        let items: [ItemPayload]?

        enum CodingKeys: String, CodingKey {
            case intent
            case referenceID = "reference_id"
            case description
            case orderAmount = "order_amount"
            case items
        }
    }

    struct AmountPayload: Encodable, Sendable {
        let amountInCents: Int
        let currency: String

        enum CodingKeys: String, CodingKey {
            case amountInCents = "amount_in_cents"
            case currency
        }
    }

    struct ItemPayload: Encodable, Sendable {
        let name: String
        let sku: String?
        let quantity: Int
        let price: AmountPayload
    }

    struct CustomerPayload: Encodable, Sendable {
        let email: String
        let firstName: String?
        let lastName: String?
        let phone: String?

        enum CodingKeys: String, CodingKey {
            case email
            case firstName = "first_name"
            case lastName = "last_name"
            case phone
        }
    }

    enum CodingKeys: String, CodingKey {
        case cancelURL = "cancel_url"
        case completeURL = "complete_url"
        case order
        case customer
    }
}

extension SessionRequest {
    static func from(_ checkout: SezzleCheckout) -> SessionRequest {
        SessionRequest(
            cancelURL: URLRef(href: "sezzle-sdk://checkout/cancelled"),
            completeURL: URLRef(href: "sezzle-sdk://checkout/confirmed"),
            order: OrderPayload(
                intent: checkout.order.intent.rawValue,
                referenceID: checkout.order.referenceId,
                description: checkout.order.description ?? "Mobile SDK Order",
                orderAmount: AmountPayload(
                    amountInCents: checkout.order.amount.amountInCents,
                    currency: checkout.order.amount.currency
                ),
                items: checkout.order.items?.map { item in
                    ItemPayload(
                        name: item.name,
                        sku: item.sku,
                        quantity: item.quantity,
                        price: AmountPayload(
                            amountInCents: item.price.amountInCents,
                            currency: item.price.currency
                        )
                    )
                }
            ),
            customer: CustomerPayload(
                email: checkout.customer.email,
                firstName: checkout.customer.firstName,
                lastName: checkout.customer.lastName,
                phone: checkout.customer.phone
            )
        )
    }
}
