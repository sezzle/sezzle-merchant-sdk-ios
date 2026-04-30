import Foundation

/// Available financing plan options to restrict checkout to specific plans.
public enum SezzleFinancingOption: String, Sendable {
    case fourPayBiweekly = "4-pay-biweekly"
    case fourPayMonthly = "4-pay-monthly"
    case sixPayMonthly = "6-pay-monthly"
}
