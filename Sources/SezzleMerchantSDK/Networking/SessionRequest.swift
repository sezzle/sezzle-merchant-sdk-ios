import Foundation
import UIKit

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

    struct AmountPayload: Encodable, Sendable {
        let amountInCents: Int
        let currency: String

        enum CodingKeys: String, CodingKey {
            case amountInCents = "amount_in_cents"
            case currency
        }
    }

    struct AddressPayload: Encodable, Sendable {
        let name: String?
        let street: String?
        let street2: String?
        let city: String?
        let state: String?
        let postalCode: String?
        let countryCode: String?
        let phone: String?

        enum CodingKeys: String, CodingKey {
            case name, street, street2, city, state
            case postalCode = "postal_code"
            case countryCode = "country_code"
            case phone
        }
    }

    struct ItemPayload: Encodable, Sendable {
        let name: String
        let sku: String?
        let quantity: Int
        let price: AmountPayload
        let brand: String?
        let imageUrl: String?
        let productUrl: String?
        let globalTradeItemNumber: String?
        let manufacturerPartNumber: String?
        let categoryPath: String?

        enum CodingKeys: String, CodingKey {
            case name, sku, quantity, price, brand
            case imageUrl = "image_url"
            case productUrl = "product_url"
            case globalTradeItemNumber = "global_trade_item_number"
            case manufacturerPartNumber = "manufacturer_part_number"
            case categoryPath = "category_path"
        }
    }

    struct DiscountPayload: Encodable, Sendable {
        let name: String
        let amount: AmountPayload
    }

    struct OrderPayload: Encodable, Sendable {
        let intent: String
        let referenceID: String
        let description: String
        let orderAmount: AmountPayload
        let items: [ItemPayload]?
        let discounts: [DiscountPayload]?
        let taxAmount: AmountPayload?
        let shippingAmount: AmountPayload?
        let metadata: [String: String]?
        let requiresShippingInfo: Bool?
        let locale: String?
        let checkoutFinancingOptions: [String]?

        enum CodingKeys: String, CodingKey {
            case intent
            case referenceID = "reference_id"
            case description
            case orderAmount = "order_amount"
            case items, discounts
            case taxAmount = "tax_amount"
            case shippingAmount = "shipping_amount"
            case metadata
            case requiresShippingInfo = "requires_shipping_info"
            case locale
            case checkoutFinancingOptions = "checkout_financing_options"
        }
    }

    struct CustomerPayload: Encodable, Sendable {
        let email: String
        let firstName: String?
        let lastName: String?
        let phone: String?
        let dob: String?
        let billingAddress: AddressPayload?
        let shippingAddress: AddressPayload?
        let tokenize: Bool?
        let recurring: Bool?
        let recurringMetadata: [String: String]?

        enum CodingKeys: String, CodingKey {
            case email
            case firstName = "first_name"
            case lastName = "last_name"
            case phone, dob
            case billingAddress = "billing_address"
            case shippingAddress = "shipping_address"
            case tokenize, recurring
            case recurringMetadata = "recurring_metadata"
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
    @MainActor
    static func from(_ checkout: SezzleCheckout) -> SessionRequest {
        // Build SDK metadata and merge with user's metadata
        var mergedMetadata: [String: String] = [
            "_sdk_platform": "ios",
            "_sdk_version": HTTPClient.sdkVersion,
            "_device_model": UIDevice.current.model,
            "_os_version": UIDevice.current.systemVersion,
        ]
        // User's metadata takes precedence (don't overwrite with underscore keys)
        if let userMeta = checkout.order.metadata {
            for (key, value) in userMeta {
                mergedMetadata[key] = value
            }
        }

        return SessionRequest(
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
                        name: item.name, sku: item.sku, quantity: item.quantity,
                        price: AmountPayload(amountInCents: item.price.amountInCents, currency: item.price.currency),
                        brand: item.brand, imageUrl: item.imageUrl, productUrl: item.productUrl,
                        globalTradeItemNumber: item.globalTradeItemNumber,
                        manufacturerPartNumber: item.manufacturerPartNumber,
                        categoryPath: item.categoryPath
                    )
                },
                discounts: checkout.order.discounts?.map { d in
                    DiscountPayload(name: d.name, amount: AmountPayload(amountInCents: d.amount.amountInCents, currency: d.amount.currency))
                },
                taxAmount: checkout.order.taxAmount.map { AmountPayload(amountInCents: $0.amountInCents, currency: $0.currency) },
                shippingAmount: checkout.order.shippingAmount.map { AmountPayload(amountInCents: $0.amountInCents, currency: $0.currency) },
                metadata: mergedMetadata,
                requiresShippingInfo: checkout.order.requiresShippingInfo,
                locale: checkout.order.locale?.rawValue,
                checkoutFinancingOptions: checkout.order.checkoutFinancingOptions?.map(\.rawValue)
            ),
            customer: CustomerPayload(
                email: checkout.customer.email,
                firstName: checkout.customer.firstName,
                lastName: checkout.customer.lastName,
                phone: checkout.customer.phone,
                dob: checkout.customer.dob,
                billingAddress: checkout.customer.billingAddress.map { a in
                    AddressPayload(name: a.name, street: a.street, street2: a.street2, city: a.city, state: a.state, postalCode: a.postalCode, countryCode: a.countryCode, phone: a.phone)
                },
                shippingAddress: checkout.customer.shippingAddress.map { a in
                    AddressPayload(name: a.name, street: a.street, street2: a.street2, city: a.city, state: a.state, postalCode: a.postalCode, countryCode: a.countryCode, phone: a.phone)
                },
                tokenize: checkout.customer.tokenize,
                recurring: checkout.customer.recurring,
                recurringMetadata: checkout.customer.recurringMetadata
            )
        )
    }
}
