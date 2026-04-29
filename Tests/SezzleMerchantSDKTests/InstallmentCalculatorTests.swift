import XCTest
@testable import SezzleMerchantSDK

final class InstallmentCalculatorTests: XCTestCase {

    // MARK: - Widget Type

    func testWidgetType_belowMinimum_hidden() {
        let type = InstallmentCalculator.widgetType(amountInCents: 3499, config: .default)
        XCTAssertEqual(type, .hidden)
    }

    func testWidgetType_aboveMaximum_hidden() {
        let type = InstallmentCalculator.widgetType(amountInCents: 250_001, config: .default)
        XCTAssertEqual(type, .hidden)
    }

    func testWidgetType_atMinimum_pi4() {
        let type = InstallmentCalculator.widgetType(amountInCents: 3500, config: .default)
        XCTAssertEqual(type, .pi4)
    }

    func testWidgetType_under50_pi4() {
        let type = InstallmentCalculator.widgetType(amountInCents: 4999, config: .default)
        XCTAssertEqual(type, .pi4)
    }

    func testWidgetType_at50_pi5() {
        let config = SezzleWidgetConfig(enablePayIn5: true)
        let type = InstallmentCalculator.widgetType(amountInCents: 5000, config: config)
        XCTAssertEqual(type, .pi5)
    }

    func testWidgetType_pi5Disabled_staysPi4() {
        let config = SezzleWidgetConfig(enablePayIn5: false)
        let type = InstallmentCalculator.widgetType(amountInCents: 14999, config: config)
        XCTAssertEqual(type, .pi4)
    }

    func testWidgetType_longTerm() {
        let config = SezzleWidgetConfig(
            longTermConfig: SezzleLongTermConfig(minPriceInCents: 25_000)
        )
        let type = InstallmentCalculator.widgetType(amountInCents: 79900, config: config)
        XCTAssertEqual(type, .longTerm)
    }

    // MARK: - Number of Payments

    func testNumberOfPayments_pi4() {
        XCTAssertEqual(InstallmentCalculator.numberOfPayments(for: .pi4), 4)
    }

    func testNumberOfPayments_pi5() {
        XCTAssertEqual(InstallmentCalculator.numberOfPayments(for: .pi5), 5)
    }

    // MARK: - Installment Math

    func testInstallments_4pay_evenlyDivisible() {
        let result = InstallmentCalculator.installments(amountInCents: 10000, numberOfPayments: 4)
        XCTAssertEqual(result, [2500, 2500, 2500, 2500])
    }

    func testInstallments_4pay_withRemainder() {
        let result = InstallmentCalculator.installments(amountInCents: 4999, numberOfPayments: 4)
        XCTAssertEqual(result[0], 1249)
        XCTAssertEqual(result[1], 1249)
        XCTAssertEqual(result[2], 1249)
        XCTAssertEqual(result[3], 1252) // absorbs remainder
        XCTAssertEqual(result.reduce(0, +), 4999)
    }

    func testInstallments_5pay() {
        let result = InstallmentCalculator.installments(amountInCents: 14999, numberOfPayments: 5)
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result.reduce(0, +), 14999)
    }

    func testInstallments_zero() {
        let result = InstallmentCalculator.installments(amountInCents: 0, numberOfPayments: 4)
        XCTAssertTrue(result.isEmpty || result.reduce(0, +) == 0)
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

    // MARK: - Payment Dates

    func testPaymentDates_4payments_biweekly() {
        let startDate = Date()
        let dates = InstallmentCalculator.paymentDates(numberOfPayments: 4, from: startDate)
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

    func testPaymentDates_5payments_biweekly() {
        let startDate = Date()
        let dates = InstallmentCalculator.paymentDates(numberOfPayments: 5, from: startDate)
        XCTAssertEqual(dates.count, 5)

        let calendar = Calendar.current
        let expected4 = calendar.date(byAdding: .day, value: 14 * 4, to: startDate)!
        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: dates[4]),
            calendar.dateComponents([.year, .month, .day], from: expected4)
        )
    }

    // MARK: - Long-Term

    func testMonthlyPayment_zeroAPR() {
        let payment = InstallmentCalculator.monthlyPayment(principalInDollars: 1200, months: 12, apr: 0)
        XCTAssertEqual(payment, 100.0, accuracy: 0.01)
    }

    func testMonthlyPayment_withAPR() {
        let payment = InstallmentCalculator.monthlyPayment(principalInDollars: 1000, months: 12, apr: 10)
        // Standard amortization formula
        XCTAssertTrue(payment > 87 && payment < 89, "Expected ~$87.92, got \(payment)")
    }

    func testLongTermOptions_returnsOptions() {
        let config = SezzleLongTermConfig(minPriceInCents: 25_000)
        let options = InstallmentCalculator.longTermOptions(amountInCents: 79900, config: config)
        XCTAssertFalse(options.isEmpty)
        for option in options {
            XCTAssertTrue(option.months > 0)
            XCTAssertTrue(option.monthlyPayment > 0)
        }
    }

    func testLowestMonthlyPayment() {
        let config = SezzleLongTermConfig(minPriceInCents: 25_000)
        let lowest = InstallmentCalculator.lowestMonthlyPayment(amountInCents: 79900, config: config)
        XCTAssertTrue(lowest > 0)
    }
}
