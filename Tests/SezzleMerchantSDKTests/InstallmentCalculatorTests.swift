import XCTest
@testable import SezzleMerchantSDK

final class InstallmentCalculatorTests: XCTestCase {

    // MARK: - Eligibility

    func testEligible_withinRange() {
        XCTAssertTrue(InstallmentCalculator.isEligible(amountInCents: 5000))
        XCTAssertTrue(InstallmentCalculator.isEligible(amountInCents: 3500))   // exact minimum
        XCTAssertTrue(InstallmentCalculator.isEligible(amountInCents: 250_000)) // exact maximum
    }

    func testNotEligible_belowMinimum() {
        XCTAssertFalse(InstallmentCalculator.isEligible(amountInCents: 3499))
        XCTAssertFalse(InstallmentCalculator.isEligible(amountInCents: 0))
    }

    func testNotEligible_aboveMaximum() {
        XCTAssertFalse(InstallmentCalculator.isEligible(amountInCents: 250_001))
    }

    // MARK: - Installment math

    func testInstallments_evenlyDivisible() {
        let result = InstallmentCalculator.installments(amountInCents: 10000) // $100.00
        XCTAssertEqual(result, [2500, 2500, 2500, 2500])
    }

    func testInstallments_withRemainder() {
        let result = InstallmentCalculator.installments(amountInCents: 4999) // $49.99
        // 4999 / 4 = 1249 remainder 3 → last payment absorbs it
        XCTAssertEqual(result[0], 1249)
        XCTAssertEqual(result[1], 1249)
        XCTAssertEqual(result[2], 1249)
        XCTAssertEqual(result[3], 1252) // 4999 - 1249*3 = 1252
        XCTAssertEqual(result.reduce(0, +), 4999)
    }

    func testInstallments_oneDollar() {
        let result = InstallmentCalculator.installments(amountInCents: 100)
        XCTAssertEqual(result, [25, 25, 25, 25])
    }

    func testInstallments_oneCent() {
        let result = InstallmentCalculator.installments(amountInCents: 1)
        // 1 / 4 = 0, remainder = 1
        XCTAssertEqual(result, [0, 0, 0, 1])
        XCTAssertEqual(result.reduce(0, +), 1)
    }

    func testInstallments_zero() {
        let result = InstallmentCalculator.installments(amountInCents: 0)
        XCTAssertEqual(result, [0, 0, 0, 0])
    }

    // MARK: - Formatting

    func testFormatCents_USD() {
        let formatted = InstallmentCalculator.formatCents(1250, currency: "USD")
        XCTAssertTrue(formatted.contains("12.50"), "Expected '12.50' in '\(formatted)'")
    }

    func testFormatCents_CAD() {
        let formatted = InstallmentCalculator.formatCents(1250, currency: "CAD")
        XCTAssertTrue(formatted.contains("12.50"), "Expected '12.50' in '\(formatted)'")
    }

    // MARK: - Payment dates

    func testPaymentDates_biweekly() {
        let startDate = Date()
        let dates = InstallmentCalculator.paymentDates(from: startDate, biweekly: true)
        XCTAssertEqual(dates.count, 4)

        let calendar = Calendar.current
        for i in 0..<4 {
            let expected = calendar.date(byAdding: .day, value: 14 * i, to: startDate)!
            XCTAssertEqual(
                calendar.dateComponents([.year, .month, .day], from: dates[i]),
                calendar.dateComponents([.year, .month, .day], from: expected)
            )
        }
    }

    func testPaymentDates_monthly() {
        let startDate = Date()
        let dates = InstallmentCalculator.paymentDates(from: startDate, biweekly: false)
        XCTAssertEqual(dates.count, 4)

        let calendar = Calendar.current
        for i in 0..<4 {
            let expected = calendar.date(byAdding: .day, value: 30 * i, to: startDate)!
            XCTAssertEqual(
                calendar.dateComponents([.year, .month, .day], from: dates[i]),
                calendar.dateComponents([.year, .month, .day], from: expected)
            )
        }
    }
}
