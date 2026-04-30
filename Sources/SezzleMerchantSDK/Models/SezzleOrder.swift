import Foundation

/// Order details for the checkout session.
public struct SezzleOrder: Sendable {
    public let referenceId: String
    public let description: String?
    public let amount: SezzleAmount
    public let intent: SezzleIntent
    public let items: [SezzleItem]?
    public let discounts: [SezzleDiscount]?
    public let taxAmount: SezzleAmount?
    public let shippingAmount: SezzleAmount?
    public let metadata: [String: String]?
    public let requiresShippingInfo: Bool?
    public let locale: SezzleLocale?
    public let checkoutFinancingOptions: [SezzleFinancingOption]?

    public init(
        referenceId: String, description: String? = nil,
        amount: SezzleAmount, intent: SezzleIntent = .auth,
        items: [SezzleItem]? = nil, discounts: [SezzleDiscount]? = nil,
        taxAmount: SezzleAmount? = nil, shippingAmount: SezzleAmount? = nil,
        metadata: [String: String]? = nil, requiresShippingInfo: Bool? = nil,
        locale: SezzleLocale? = nil,
        checkoutFinancingOptions: [SezzleFinancingOption]? = nil
    ) {
        self.referenceId = referenceId; self.description = description
        self.amount = amount; self.intent = intent; self.items = items
        self.discounts = discounts; self.taxAmount = taxAmount
        self.shippingAmount = shippingAmount; self.metadata = metadata
        self.requiresShippingInfo = requiresShippingInfo; self.locale = locale
        self.checkoutFinancingOptions = checkoutFinancingOptions
    }
}
