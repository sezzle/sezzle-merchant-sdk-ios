import Foundation

/// A monetary amount in the smallest currency unit (cents).
///
/// ```swift
/// let amount = SezzleAmount(amountInCents: 4999, currency: "USD")
/// ```
public struct SezzleAmount: Sendable {
    /// The amount in cents (e.g., 4999 = $49.99).
    public let amountInCents: Int
    /// ISO 4217 currency code (e.g., "USD", "CAD").
    public let currency: String

    public init(amountInCents: Int, currency: String) {
        self.amountInCents = amountInCents
        self.currency = currency
    }
}
