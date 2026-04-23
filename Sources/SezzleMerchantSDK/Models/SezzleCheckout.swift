import Foundation

/// Groups customer and order data for a checkout session.
///
/// ```swift
/// let checkout = SezzleCheckout(
///     customer: SezzleCustomer(email: "jane@example.com"),
///     order: SezzleOrder(
///         referenceId: "order-123",
///         amount: SezzleAmount(amountInCents: 4999, currency: "USD")
///     )
/// )
/// ```
public struct SezzleCheckout: Sendable {
    /// The customer placing the order.
    public let customer: SezzleCustomer
    /// The order details.
    public let order: SezzleOrder

    public init(customer: SezzleCustomer, order: SezzleOrder) {
        self.customer = customer
        self.order = order
    }
}
