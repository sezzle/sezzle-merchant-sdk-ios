import Foundation

/// A line item in the order.
///
/// ```swift
/// let item = SezzleItem(
///     name: "Blue Widget",
///     sku: "widget-blue-001",
///     quantity: 2,
///     price: SezzleAmount(amountInCents: 2499, currency: "USD")
/// )
/// ```
public struct SezzleItem: Sendable {
    /// The display name of the item.
    public let name: String
    /// Optional SKU or product identifier.
    public let sku: String?
    /// The quantity of this item.
    public let quantity: Int
    /// The unit price of this item.
    public let price: SezzleAmount

    public init(name: String, sku: String? = nil, quantity: Int, price: SezzleAmount) {
        self.name = name
        self.sku = sku
        self.quantity = quantity
        self.price = price
    }
}
