import Foundation

/// The type of promotional widget to display based on price and config.
public enum SezzleWidgetType: Sendable {
    /// Price below minimum — don't show widget.
    case hidden
    /// Standard 4-payment plan.
    case pi4
    /// 5-payment plan (price >= $50 and PI5 enabled).
    case pi5
    /// Long-term monthly payments with interest.
    case longTerm
}

/// Calculates installment amounts, payment dates, and determines widget type.
enum InstallmentCalculator {

    // MARK: - Widget Type

    /// Determine which widget type to show for a given price.
    static func widgetType(amountInCents: Int, config: SezzleWidgetConfig) -> SezzleWidgetType {
        // Below minimum — hidden
        if amountInCents < config.minPriceInCents {
            return .hidden
        }

        // Check long-term eligibility first (takes priority in the widget)
        if let ltConfig = config.longTermConfig,
           amountInCents >= ltConfig.minPriceInCents,
           amountInCents <= ltConfig.maxPriceInCents {
            return .longTerm
        }

        // Above max price and not LT eligible — hidden
        if amountInCents > config.maxPriceInCents {
            return .hidden
        }

        // PI5: enabled + price >= threshold
        if config.enablePayIn5, amountInCents >= config.pi5MinPriceInCents {
            return .pi5
        }

        return .pi4
    }

    /// Number of payments for the given widget type.
    static func numberOfPayments(for type: SezzleWidgetType) -> Int {
        switch type {
        case .pi4: return 4
        case .pi5: return 5
        case .longTerm, .hidden: return 0
        }
    }

    // MARK: - Short-Term (PI4/PI5)

    /// Calculate installment amounts for PI4 or PI5.
    ///
    /// First N-1 payments are equal (rounded down). Last payment absorbs remainder.
    static func installments(amountInCents: Int, numberOfPayments: Int) -> [Int] {
        guard amountInCents > 0, numberOfPayments > 0 else { return [] }
        let base = amountInCents / numberOfPayments
        let remainder = amountInCents - (base * (numberOfPayments - 1))
        var result = Array(repeating: base, count: numberOfPayments - 1)
        result.append(remainder)
        return result
    }

    /// Payment dates for short-term plans (biweekly — every 2 weeks).
    static func paymentDates(numberOfPayments: Int, from startDate: Date = Date()) -> [Date] {
        let calendar = Calendar.current
        return (0..<numberOfPayments).map { index in
            calendar.date(byAdding: .day, value: 14 * index, to: startDate) ?? startDate
        }
    }

    // MARK: - Long-Term (Monthly with APR)

    /// Calculate monthly payment with interest using amortization formula.
    ///
    /// Matches sezzle-js `LongTermPayment.#calculatePayment`.
    static func monthlyPayment(principalInDollars: Double, months: Int, apr: Double) -> Double {
        guard months > 0 else { return 0 }
        if apr > 0 {
            let monthlyRate = apr / 100.0 / 12.0
            let interest = pow(1 + monthlyRate, Double(months))
            return (principalInDollars * monthlyRate * interest) / (interest - 1)
        } else {
            return principalInDollars / Double(months)
        }
    }

    /// Get available long-term payment options for a price.
    ///
    /// Returns options sorted by monthly payment ascending (lowest first).
    static func longTermOptions(amountInCents: Int, config: SezzleLongTermConfig) -> [LongTermOption] {
        let priceInDollars = Double(amountInCents) / 100.0
        let terms = paymentTerms(forPriceInDollars: priceInDollars, tiers: config.paymentTerms)

        var options = terms.map { (months, apr) -> LongTermOption in
            let monthly = monthlyPayment(principalInDollars: priceInDollars, months: months, apr: apr)
            let total = (monthly * Double(months) * 100).rounded() / 100
            let interest = total - priceInDollars
            return LongTermOption(
                months: months,
                apr: apr,
                monthlyPayment: monthly,
                totalAmount: total,
                totalInterest: interest
            )
        }

        options.sort { $0.monthlyPayment < $1.monthlyPayment }
        return options
    }

    /// Get the lowest available monthly payment for the widget text.
    static func lowestMonthlyPayment(amountInCents: Int, config: SezzleLongTermConfig) -> Double {
        let priceInDollars = Double(amountInCents) / 100.0
        let terms = paymentTerms(forPriceInDollars: priceInDollars, tiers: config.paymentTerms)
        guard let longest = terms.first else { return priceInDollars }
        return monthlyPayment(principalInDollars: priceInDollars, months: longest.months, apr: longest.apr)
    }

    /// Find the payment terms for a given price from the tier list.
    private static func paymentTerms(forPriceInDollars price: Double, tiers: [SezzleLongTermTier]) -> [(months: Int, apr: Double)] {
        for tier in tiers {
            if price > tier.priceThreshold {
                return tier.options
            }
        }
        return tiers.last?.options ?? []
    }

    // MARK: - Formatting

    /// Format cents as a currency string (e.g., 1250 → "$12.50").
    static func formatCents(_ cents: Int, currency: String = "USD") -> String {
        let dollars = Double(cents) / 100.0
        return formatDollars(dollars, currency: currency)
    }

    /// Format a dollar amount as a currency string.
    static func formatDollars(_ dollars: Double, currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: dollars)) ?? "$\(String(format: "%.2f", dollars))"
    }
}

/// A long-term payment option with calculated values.
struct LongTermOption {
    let months: Int
    let apr: Double
    let monthlyPayment: Double
    let totalAmount: Double
    let totalInterest: Double
}
