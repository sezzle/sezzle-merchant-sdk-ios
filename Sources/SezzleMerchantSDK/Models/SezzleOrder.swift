import Foundation

/// Order details for the checkout session.
///
/// ```swift
/// let order = SezzleOrder(
///     referenceId: "order-123",
///     amount: SezzleAmount(amountInCents: 4999, currency: "USD"),
///     items: [
///         SezzleItem(name: "Widget", quantity: 1, price: SezzleAmount(amountInCents: 4999, currency: "USD"))
///     ]
/// )
/// ```
public struct SezzleOrder: Sendable {
    /// Your internal order or reference ID.
    public let referenceId: String
    /// Optional order description.
    public let description: String?
    /// The total order amount.
    public let amount: SezzleAmount
    /// The payment intent. Defaults to `.auth`.
    public let intent: SezzleIntent
    /// Optional line items in the order.
    public let items: [SezzleItem]?

    public init(
        referenceId: String,
        description: String? = nil,
        amount: SezzleAmount,
        intent: SezzleIntent = .auth,
        items: [SezzleItem]? = nil
    ) {
        self.referenceId = referenceId
        self.description = description
        self.amount = amount
        self.intent = intent
        self.items = items
    }
}
