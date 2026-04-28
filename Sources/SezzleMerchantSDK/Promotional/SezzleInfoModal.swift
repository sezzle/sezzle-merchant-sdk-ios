import UIKit

/// An educational modal that explains how Sezzle works.
///
/// Shows different content based on widget type:
/// - PI4: 4-payment biweekly breakdown with pie charts
/// - PI5: 5-payment biweekly breakdown with pie charts
/// - Long-term: Monthly payment options with APR terms
@MainActor
public final class SezzleInfoModal {
    /// Present the Sezzle info modal.
    public static func present(
        amountInCents: Int,
        currency: String = "USD",
        widgetType: SezzleWidgetType? = nil,
        widgetConfig: SezzleWidgetConfig = .default,
        from viewController: UIViewController
    ) {
        let type = widgetType ?? InstallmentCalculator.widgetType(amountInCents: amountInCents, config: widgetConfig)
        let modal = SezzleInfoViewController(
            amountInCents: amountInCents,
            currency: currency,
            widgetType: type,
            widgetConfig: widgetConfig
        )
        let nav = UINavigationController(rootViewController: modal)
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *), let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        viewController.present(nav, animated: true)
    }
}

/// Internal view controller for the info modal content.
@MainActor
final class SezzleInfoViewController: UIViewController {
    private let amountInCents: Int
    private let currency: String
    private let widgetType: SezzleWidgetType
    private let widgetConfig: SezzleWidgetConfig

    init(amountInCents: Int, currency: String, widgetType: SezzleWidgetType, widgetConfig: SezzleWidgetConfig) {
        self.amountInCents = amountInCents
        self.currency = currency
        self.widgetType = widgetType
        self.widgetConfig = widgetConfig
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(dismissModal)
        )
        view.backgroundColor = .systemBackground
        setupContent()
    }

    @objc private func dismissModal() {
        dismiss(animated: true)
    }

    private func setupContent() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),
        ])

        // Sezzle logo
        let isDark = traitCollection.userInterfaceStyle == .dark
        let logoName = isDark ? "sezzle_logo_dark" : "sezzle_logo"
        if let logoURL = SezzleBundle.resourceBundle.url(forResource: logoName, withExtension: "png"),
           let logoData = try? Data(contentsOf: logoURL),
           let logoImage = UIImage(data: logoData) {
            let logoView = UIImageView(image: logoImage)
            logoView.contentMode = .scaleAspectFit
            logoView.translatesAutoresizingMaskIntoConstraints = false
            logoView.heightAnchor.constraint(equalToConstant: 28).isActive = true
            logoView.widthAnchor.constraint(equalToConstant: 28 * (logoImage.size.width / logoImage.size.height)).isActive = true
            stack.addArrangedSubview(logoView)
        }

        switch widgetType {
        case .pi4, .pi5:
            buildShortTermContent(stack: stack)
        case .longTerm:
            buildLongTermContent(stack: stack)
        case .hidden:
            break
        }
    }

    // MARK: - Short-Term (PI4/PI5)

    private func buildShortTermContent(stack: UIStackView) {
        let numPayments = InstallmentCalculator.numberOfPayments(for: widgetType)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "\(numPayments) easy payments"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = SezzleBrand.darkPurple
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Split your purchase into \(numPayments) payments,\nevery 2 weeks. No hidden fees."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = SezzleBrand.gray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        stack.addArrangedSubview(subtitleLabel)

        // Payment schedule card
        let scheduleCard = createScheduleCard(numberOfPayments: numPayments)
        stack.addArrangedSubview(scheduleCard)
        scheduleCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        // Footer
        let footerLabel = UILabel()
        footerLabel.text = "No hidden fees \u{00B7} No impact to your credit score"
        footerLabel.font = .systemFont(ofSize: 12)
        footerLabel.textColor = SezzleBrand.gray
        footerLabel.textAlignment = .center
        footerLabel.numberOfLines = 0
        stack.addArrangedSubview(footerLabel)
    }

    private func createScheduleCard(numberOfPayments: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = SezzleBrand.lightPurpleBg
        card.layer.cornerRadius = 12

        let installments = InstallmentCalculator.installments(amountInCents: amountInCents, numberOfPayments: numberOfPayments)
        let dates = InstallmentCalculator.paymentDates(numberOfPayments: numberOfPayments)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.distribution = .equalSpacing
        hStack.alignment = .top
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        for (index, (amount, date)) in zip(installments, dates).enumerated() {
            let formatted = InstallmentCalculator.formatCents(amount, currency: currency)
            let dateString = index == 0 ? "Today" : dateFormatter.string(from: date)
            let weekLabel = index == 0 ? "" : "Wk \(index * 2)"
            let paymentView = createPaymentColumn(
                step: index + 1,
                total: numberOfPayments,
                amount: formatted,
                dateLabel: dateString,
                weekLabel: weekLabel,
                isFirst: index == 0
            )
            hStack.addArrangedSubview(paymentView)
        }

        return card
    }

    private func createPaymentColumn(step: Int, total: Int, amount: String, dateLabel: String, weekLabel: String, isFirst: Bool) -> UIView {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 4
        column.alignment = .center

        // Dot indicator
        let dotSize: CGFloat = total <= 4 ? 36 : 28
        let pie = SezzleBrand.pieChartView(step: step, totalSteps: total, size: dotSize, isDark: isDark)
        column.addArrangedSubview(pie)

        // Amount
        let amountLabel = UILabel()
        amountLabel.text = amount
        amountLabel.font = .systemFont(ofSize: total <= 4 ? 13 : 11, weight: .bold)
        amountLabel.textColor = SezzleBrand.scheduleAmount
        amountLabel.textAlignment = .center
        column.addArrangedSubview(amountLabel)

        // Date
        let dateText = UILabel()
        dateText.text = dateLabel
        dateText.font = .systemFont(ofSize: 10)
        dateText.textColor = isFirst ? SezzleBrand.green : SezzleBrand.scheduleDate
        dateText.textAlignment = .center
        column.addArrangedSubview(dateText)

        return column
    }

    // MARK: - Long-Term (Monthly with APR)

    private func buildLongTermContent(stack: UIStackView) {
        guard let ltConfig = widgetConfig.longTermConfig else { return }

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Flexible monthly payments"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = SezzleBrand.darkPurple
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Choose a payment plan that works for you."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = SezzleBrand.gray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        stack.addArrangedSubview(subtitleLabel)

        // Price header
        let priceLabel = UILabel()
        priceLabel.text = "Sample payments for \(InstallmentCalculator.formatCents(amountInCents, currency: currency))"
        priceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        priceLabel.textColor = SezzleBrand.darkPurple
        priceLabel.textAlignment = .center
        stack.addArrangedSubview(priceLabel)

        // Payment options
        let options = InstallmentCalculator.longTermOptions(amountInCents: amountInCents, config: ltConfig)
        for option in options {
            let optionCard = createLongTermOptionCard(option: option)
            stack.addArrangedSubview(optionCard)
            optionCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }

        // APR disclosure
        let aprLabel = UILabel()
        aprLabel.text = "Rates from \(ltConfig.minAPR)% – \(ltConfig.maxAPR)% APR. Subject to credit approval."
        aprLabel.font = .systemFont(ofSize: 11)
        aprLabel.textColor = SezzleBrand.gray
        aprLabel.textAlignment = .center
        aprLabel.numberOfLines = 0
        stack.addArrangedSubview(aprLabel)
    }

    private func createLongTermOptionCard(option: LongTermOption) -> UIView {
        let card = UIView()
        card.backgroundColor = SezzleBrand.lightPurpleBg
        card.layer.cornerRadius = 10

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.distribution = .equalSpacing
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])

        // Term
        let termStack = UIStackView()
        termStack.axis = .vertical
        termStack.spacing = 2
        let monthsLabel = UILabel()
        monthsLabel.text = "\(option.months) months"
        monthsLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        monthsLabel.textColor = SezzleBrand.darkPurple
        termStack.addArrangedSubview(monthsLabel)
        let aprText = UILabel()
        aprText.text = option.apr > 0 ? "\(String(format: "%.2f", option.apr))% APR" : "0% APR"
        aprText.font = .systemFont(ofSize: 12)
        aprText.textColor = SezzleBrand.gray
        termStack.addArrangedSubview(aprText)
        hStack.addArrangedSubview(termStack)

        // Monthly payment
        let paymentStack = UIStackView()
        paymentStack.axis = .vertical
        paymentStack.spacing = 2
        paymentStack.alignment = .trailing
        let paymentLabel = UILabel()
        paymentLabel.text = InstallmentCalculator.formatDollars(option.monthlyPayment, currency: currency)
        paymentLabel.font = .systemFont(ofSize: 15, weight: .bold)
        paymentLabel.textColor = SezzleBrand.purple
        paymentStack.addArrangedSubview(paymentLabel)
        let perMonthLabel = UILabel()
        perMonthLabel.text = "per month"
        perMonthLabel.font = .systemFont(ofSize: 12)
        perMonthLabel.textColor = SezzleBrand.gray
        paymentStack.addArrangedSubview(perMonthLabel)
        hStack.addArrangedSubview(paymentStack)

        return card
    }
}
