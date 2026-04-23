import Foundation

/// Calculates installment amounts and payment dates for Sezzle's 4-payment model.
enum InstallmentCalculator {
    /// Minimum order amount in cents ($35.00).
    static let minimumAmountInCents = 3500
    /// Maximum order amount in cents ($2,500.00).
    static let maximumAmountInCents = 250_000

    /// Whether the given amount is eligible for installment messaging.
    static func isEligible(amountInCents: Int) -> Bool {
        amountInCents >= minimumAmountInCents && amountInCents <= maximumAmountInCents
    }

    /// Calculate the four installment amounts in cents.
    ///
    /// The first three payments are equal (rounded down). The fourth absorbs the remainder.
    /// For example, $49.99 (4999 cents) → [1249, 1249, 1249, 1252].
    static func installments(amountInCents: Int) -> [Int] {
        guard amountInCents > 0 else { return [0, 0, 0, 0] }
        let base = amountInCents / 4
        let remainder = amountInCents - (base * 3)
        return [base, base, base, remainder]
    }

    /// Format cents as a currency string (e.g., 1250 → "$12.50").
    static func formatCents(_ cents: Int, currency: String = "USD") -> String {
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: dollars)) ?? "$\(String(format: "%.2f", dollars))"
    }

    /// Calculate payment due dates starting from today.
    ///
    /// US/CA uses biweekly (14-day) intervals. Other regions use monthly (30-day) intervals.
    static func paymentDates(from startDate: Date = Date(), biweekly: Bool = true) -> [Date] {
        let interval = biweekly ? 14 : 30
        let calendar = Calendar.current
        return (0..<4).map { index in
            calendar.date(byAdding: .day, value: interval * index, to: startDate) ?? startDate
        }
    }
}
