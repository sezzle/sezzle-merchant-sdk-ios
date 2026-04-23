import UIKit

/// An educational modal that explains how Sezzle works.
///
/// Shows a 4-payment breakdown with pie chart progression, dates, and the Sezzle brand.
/// Automatically presented when a user taps ``SezzlePromotionalView``, or present manually:
///
/// ```swift
/// SezzleInfoModal.present(amountInCents: 4999, from: self)
/// ```
@MainActor
public final class SezzleInfoModal {
    /// Present the Sezzle info modal.
    ///
    /// - Parameters:
    ///   - amountInCents: The order amount in cents.
    ///   - currency: ISO 4217 currency code. Defaults to "USD".
    ///   - viewController: The view controller to present from.
    public static func present(
        amountInCents: Int,
        currency: String = "USD",
        from viewController: UIViewController
    ) {
        let modal = SezzleInfoViewController(amountInCents: amountInCents, currency: currency)
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

    init(amountInCents: Int, currency: String) {
        self.amountInCents = amountInCents
        self.currency = currency
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
        let logoContainer = UIView()
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        let logoLabel = UILabel()
        logoLabel.text = "✦ sezzle"
        logoLabel.font = .systemFont(ofSize: 22, weight: .bold)
        logoLabel.textColor = SezzleBrand.darkPurple
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.addSubview(logoLabel)
        NSLayoutConstraint.activate([
            logoLabel.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoLabel.topAnchor.constraint(equalTo: logoContainer.topAnchor),
            logoLabel.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor),
        ])
        stack.addArrangedSubview(logoContainer)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "4 interest-free payments"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = SezzleBrand.darkPurple
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        stack.addArrangedSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Split your purchase and pay over time.\nNo fees. No interest. No surprises."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = SezzleBrand.gray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        stack.addArrangedSubview(subtitleLabel)

        // Payment schedule card
        let scheduleCard = createScheduleCard()
        stack.addArrangedSubview(scheduleCard)
        scheduleCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        // Footer
        let footerLabel = UILabel()
        footerLabel.text = "No interest · No hidden fees · No impact to your credit score"
        footerLabel.font = .systemFont(ofSize: 12)
        footerLabel.textColor = SezzleBrand.gray
        footerLabel.textAlignment = .center
        footerLabel.numberOfLines = 0
        stack.addArrangedSubview(footerLabel)
    }

    private func createScheduleCard() -> UIView {
        let card = UIView()
        card.backgroundColor = SezzleBrand.lightPurpleBg
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false

        let installments = InstallmentCalculator.installments(amountInCents: amountInCents)
        let dates = InstallmentCalculator.paymentDates()
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
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        for (index, (amount, date)) in zip(installments, dates).enumerated() {
            let formatted = InstallmentCalculator.formatCents(amount, currency: currency)
            let dateString = index == 0 ? "Today" : dateFormatter.string(from: date)
            let paymentView = createPaymentColumn(
                step: index + 1,
                amount: formatted,
                dateLabel: dateString,
                isFirst: index == 0
            )
            hStack.addArrangedSubview(paymentView)
        }

        return card
    }

    private func createPaymentColumn(step: Int, amount: String, dateLabel: String, isFirst: Bool) -> UIView {
        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 6
        column.alignment = .center

        // Pie chart
        let pie = SezzleBrand.pieChartView(step: step, size: 40)
        column.addArrangedSubview(pie)

        // Amount
        let amountLabel = UILabel()
        amountLabel.text = amount
        amountLabel.font = .systemFont(ofSize: 14, weight: .medium)
        amountLabel.textColor = SezzleBrand.purple
        amountLabel.textAlignment = .center
        column.addArrangedSubview(amountLabel)

        // Date
        let dateText = UILabel()
        dateText.text = dateLabel
        dateText.font = .systemFont(ofSize: 10)
        dateText.textColor = isFirst ? SezzleBrand.green : SezzleBrand.gray
        dateText.textAlignment = .center
        column.addArrangedSubview(dateText)

        return column
    }
}
