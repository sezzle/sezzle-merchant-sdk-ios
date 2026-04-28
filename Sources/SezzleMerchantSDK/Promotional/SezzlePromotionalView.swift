import UIKit

/// A drop-in view that displays Sezzle installment messaging with brand styling.
///
/// Shows different messages based on the price:
/// - Under $50: "or 4 payments of $X.XX with Sezzle"
/// - $50+: "or 5 payments of $X.XX with Sezzle" (when PI5 enabled)
/// - Long-term eligible: "or monthly payments as low as $X.XX with Sezzle"
/// - Below min or above max: hidden
///
/// Tapping opens the appropriate info modal.
@MainActor
public final class SezzlePromotionalView: UIView {
    private let messageLabel = UILabel()
    private var style: SezzlePromotionalStyle
    private var amountInCents: Int
    private var currency: String
    private var widgetConfig: SezzleWidgetConfig
    private weak var presentingViewController: UIViewController?

    /// Create a promotional view.
    ///
    /// - Parameters:
    ///   - amountInCents: The product or cart total in cents.
    ///   - currency: ISO 4217 currency code. Defaults to "USD".
    ///   - style: Visual style. Defaults to `.light`.
    ///   - widgetConfig: Widget configuration. Defaults to standard config.
    ///   - viewController: The view controller used to present the info modal on tap.
    public init(
        amountInCents: Int,
        currency: String = "USD",
        style: SezzlePromotionalStyle = .light,
        widgetConfig: SezzleWidgetConfig = .default,
        presentingFrom viewController: UIViewController
    ) {
        self.amountInCents = amountInCents
        self.currency = currency
        self.style = style
        self.widgetConfig = widgetConfig
        self.presentingViewController = viewController
        super.init(frame: .zero)
        setupView()
        render()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Update the displayed amount.
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
        let type = InstallmentCalculator.widgetType(amountInCents: amountInCents, config: widgetConfig)

        guard type != .hidden else {
            isHidden = true
            return
        }

        isHidden = false
        // Auto-detect dark mode for the default style
        let effectiveStyle: SezzlePromotionalStyle
        if style.logoVariant == .dark && traitCollection.userInterfaceStyle == .dark {
            effectiveStyle = .dark
        } else {
            effectiveStyle = style
        }
        let attributed = SezzlePromoDataHandler.buildAttributedMessage(
            amountInCents: amountInCents,
            widgetType: type,
            currency: currency,
            style: effectiveStyle,
            widgetConfig: widgetConfig
        )
        messageLabel.attributedText = attributed
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            render()
        }
    }

    @objc private func handleTap() {
        guard let vc = presentingViewController else { return }
        let type = InstallmentCalculator.widgetType(amountInCents: amountInCents, config: widgetConfig)
        SezzleInfoModal.present(
            amountInCents: amountInCents,
            currency: currency,
            widgetType: type,
            widgetConfig: widgetConfig,
            from: vc
        )
    }
}
