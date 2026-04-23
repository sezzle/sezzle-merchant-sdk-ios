import UIKit

/// A drop-in view that displays Sezzle installment messaging with brand styling.
///
/// Place this on product pages, cart pages, or anywhere you want to show
/// "or 4 interest-free payments of $X.XX with Sezzle". Tapping the view
/// opens ``SezzleInfoModal`` automatically.
///
/// ```swift
/// let promoView = SezzlePromotionalView(
///     amountInCents: product.priceInCents,
///     presentingFrom: self
/// )
/// stackView.addArrangedSubview(promoView)
/// ```
@MainActor
public final class SezzlePromotionalView: UIView {
    private let messageLabel = UILabel()
    private var style: SezzlePromotionalStyle
    private var amountInCents: Int
    private var currency: String
    private weak var presentingViewController: UIViewController?

    /// Create a promotional view.
    ///
    /// - Parameters:
    ///   - amountInCents: The product or cart total in cents.
    ///   - currency: ISO 4217 currency code. Defaults to "USD".
    ///   - style: Visual style. Defaults to `.light`.
    ///   - viewController: The view controller used to present the info modal on tap.
    public init(
        amountInCents: Int,
        currency: String = "USD",
        style: SezzlePromotionalStyle = .light,
        presentingFrom viewController: UIViewController
    ) {
        self.amountInCents = amountInCents
        self.currency = currency
        self.style = style
        self.presentingViewController = viewController
        super.init(frame: .zero)
        setupView()
        render()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Update the displayed amount.
    ///
    /// Call this when the cart total or product price changes.
    /// The view auto-hides if the amount falls below the $35 minimum.
    public func update(amountInCents: Int) {
        self.amountInCents = amountInCents
        render()
    }

    private func setupView() {
        messageLabel.numberOfLines = 0
        messageLabel.isUserInteractionEnabled = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    private func render() {
        guard InstallmentCalculator.isEligible(amountInCents: amountInCents) else {
            isHidden = true
            return
        }

        isHidden = false
        let installments = InstallmentCalculator.installments(amountInCents: amountInCents)
        let formatted = InstallmentCalculator.formatCents(installments[0], currency: currency)

        // Use the shared builder which handles logo inline
        let attributed = NSMutableAttributedString(
            attributedString: SezzlePromoDataHandler.buildAttributedMessage(
                installmentAmount: formatted,
                style: style
            )
        )

        // Info icon in purple — use non-breaking space so logo and ⓘ stay on the same line
        attributed.append(NSAttributedString(
            string: "\u{00A0}ⓘ",
            attributes: [
                .font: UIFont.systemFont(ofSize: style.font.pointSize - 1),
                .foregroundColor: SezzleBrand.purple
            ]
        ))

        // Add line spacing for breathing room when text wraps
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        attributed.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributed.length))

        messageLabel.attributedText = attributed
    }

    @objc private func handleTap() {
        guard let vc = presentingViewController else { return }
        SezzleInfoModal.present(amountInCents: amountInCents, currency: currency, from: vc)
    }
}
