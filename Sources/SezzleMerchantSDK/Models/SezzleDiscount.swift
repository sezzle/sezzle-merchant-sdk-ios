import Foundation

/// A discount applied to the order.
public struct SezzleDiscount: Sendable {
    public let name: String
    public let amount: SezzleAmount

    public init(name: String, amount: SezzleAmount) {
        self.name = name; self.amount = amount
    }
}
