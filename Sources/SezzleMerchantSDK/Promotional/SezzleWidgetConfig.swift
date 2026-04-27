import Foundation

/// Configuration for Sezzle promotional messaging.
///
/// Controls which widget template is shown based on the product price:
/// - Below `minPriceInCents`: widget hidden
/// - Below PI5 threshold ($50): "or 4 payments of $X with Sezzle"
/// - At/above PI5 threshold: "or 5 payments of $X with Sezzle" (when `enablePayIn5` is true)
/// - At/above long-term min: "or monthly payments as low as $X with Sezzle"
/// - Above `maxPriceInCents` (and no LT): widget hidden
public struct SezzleWidgetConfig: Sendable {
    /// Minimum price in cents for the widget to display. Default: 3500 ($35).
    public var minPriceInCents: Int

    /// Maximum price in cents for PI4/PI5 eligibility. Default: 250000 ($2,500).
    public var maxPriceInCents: Int

    /// Enable 5-payment option for prices >= $50. Default: true (matches US widget behavior).
    public var enablePayIn5: Bool

    /// PI5 price threshold in cents. Prices at or above this show 5 payments. Default: 5000 ($50).
    public var pi5MinPriceInCents: Int

    /// Long-term payment configuration. Nil = disabled (default).
    public var longTermConfig: SezzleLongTermConfig?

    /// Currency code. Default: "USD".
    public var currency: String

    public init(
        minPriceInCents: Int = 3500,
        maxPriceInCents: Int = 250_000,
        enablePayIn5: Bool = true,
        pi5MinPriceInCents: Int = 5000,
        longTermConfig: SezzleLongTermConfig? = nil,
        currency: String = "USD"
    ) {
        self.minPriceInCents = minPriceInCents
        self.maxPriceInCents = maxPriceInCents
        self.enablePayIn5 = enablePayIn5
        self.pi5MinPriceInCents = pi5MinPriceInCents
        self.longTermConfig = longTermConfig
        self.currency = currency
    }

    /// Default configuration matching sezzle-js for US merchants.
    public static let `default` = SezzleWidgetConfig()
}

/// Long-term (monthly) payment configuration.
public struct SezzleLongTermConfig: Sendable {
    /// Minimum price in cents for long-term eligibility. Default: 10000 ($100).
    public var minPriceInCents: Int

    /// Maximum price in cents for long-term eligibility. Default: 4_000_000 ($40,000).
    public var maxPriceInCents: Int

    /// Payment term tiers — sorted by price descending. Each tier has a price threshold
    /// and a list of `[months, APR%]` options.
    public var paymentTerms: [SezzleLongTermTier]

    /// Minimum APR shown in disclosure text. Default: "9.99".
    public var minAPR: String

    /// Maximum APR shown in disclosure text. Default: "34.99".
    public var maxAPR: String

    public init(
        minPriceInCents: Int = 10_000,
        maxPriceInCents: Int = 4_000_000,
        paymentTerms: [SezzleLongTermTier]? = nil,
        minAPR: String = "9.99",
        maxAPR: String = "34.99"
    ) {
        self.minPriceInCents = minPriceInCents
        self.maxPriceInCents = maxPriceInCents
        self.paymentTerms = paymentTerms ?? SezzleLongTermTier.defaults
        self.minAPR = minAPR
        self.maxAPR = maxAPR
    }
}

/// A price tier for long-term payment options.
public struct SezzleLongTermTier: Sendable {
    /// Price threshold in dollars (products above this price use these options).
    public var priceThreshold: Double

    /// Available payment options: each is (months, APR%).
    public var options: [(months: Int, apr: Double)]

    public init(priceThreshold: Double, options: [(months: Int, apr: Double)]) {
        self.priceThreshold = priceThreshold
        self.options = options
    }

    /// Default tiers matching sezzle-js.
    public static let defaults: [SezzleLongTermTier] = [
        SezzleLongTermTier(priceThreshold: 1000, options: [(48, 8.99), (36, 7.99), (3, 0.0)]),
        SezzleLongTermTier(priceThreshold: 500, options: [(24, 7.99), (12, 6.99), (3, 0.0)]),
        SezzleLongTermTier(priceThreshold: 250, options: [(12, 6.99), (9, 5.99), (3, 0.0)]),
        SezzleLongTermTier(priceThreshold: 100, options: [(9, 5.99), (6, 5.99), (3, 0.0)]),
    ]
}
