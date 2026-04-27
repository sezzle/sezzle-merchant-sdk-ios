import UIKit

/// Provides raw promotional message data for custom UI implementations.
///
/// Use this when you want to build your own promotional UI instead of using ``SezzlePromotionalView``.
public enum SezzlePromoDataHandler {
    /// Get a promotional message as an attributed string with the Sezzle logo inline.
    ///
    /// - Parameters:
    ///   - amountInCents: The total order amount in cents.
    ///   - currency: ISO 4217 currency code. Defaults to "USD".
    ///   - style: The visual style. Defaults to `.light`.
    ///   - widgetConfig: Widget configuration. Defaults to standard config.
    ///   - completion: Called on the main thread with the attributed string.
    ///     Returns an empty string if the amount is not eligible.
    @MainActor
    public static func getMessage(
        amountInCents: Int,
        currency: String = "USD",
        style: SezzlePromotionalStyle = .light,
        widgetConfig: SezzleWidgetConfig = .default,
        completion: @MainActor @Sendable (NSAttributedString) -> Void
    ) {
        let type = InstallmentCalculator.widgetType(amountInCents: amountInCents, config: widgetConfig)

        guard type != .hidden else {
            completion(NSAttributedString())
            return
        }

        let message = buildAttributedMessage(
            amountInCents: amountInCents,
            widgetType: type,
            currency: currency,
            style: style,
            widgetConfig: widgetConfig
        )
        completion(message)
    }

    /// The bundled Sezzle logo, loaded once from the SDK's resource bundle.
    @MainActor
    private static var cachedLogo: UIImage? = {
        // CocoaPods resource bundle
        let frameworkBundle = Bundle(for: SezzlePromotionalView.self)
        if let podBundleURL = frameworkBundle.url(forResource: "SezzleMerchantSDK", withExtension: "bundle"),
           let podBundle = Bundle(url: podBundleURL),
           let url = podBundle.url(forResource: "sezzle_logo", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        // SPM / direct framework — resources in the same bundle
        if let url = frameworkBundle.url(forResource: "sezzle_logo", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }()

    @MainActor
    static func buildAttributedMessage(
        amountInCents: Int,
        widgetType: SezzleWidgetType,
        currency: String,
        style: SezzlePromotionalStyle,
        widgetConfig: SezzleWidgetConfig
    ) -> NSAttributedString {
        let attributed = NSMutableAttributedString()

        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: SezzleBrand.darkPurple
        ]

        switch widgetType {
        case .pi4, .pi5:
            let numPayments = InstallmentCalculator.numberOfPayments(for: widgetType)
            let installments = InstallmentCalculator.installments(amountInCents: amountInCents, numberOfPayments: numPayments)
            let formatted = InstallmentCalculator.formatCents(installments[0], currency: currency)

            // "or X payments of "
            attributed.append(NSAttributedString(
                string: "or\u{00A0}\(numPayments)\u{00A0}payments\u{00A0}of ",
                attributes: baseAttrs
            ))

            // "$XX.XX" in purple bold
            attributed.append(NSAttributedString(
                string: formatted,
                attributes: [
                    .font: UIFont.systemFont(ofSize: style.font.pointSize, weight: .bold),
                    .foregroundColor: SezzleBrand.purple
                ]
            ))

            // " with "
            attributed.append(NSAttributedString(string: "\u{00A0}with ", attributes: baseAttrs))

        case .longTerm:
            guard let ltConfig = widgetConfig.longTermConfig else { return attributed }
            let lowestPayment = InstallmentCalculator.lowestMonthlyPayment(amountInCents: amountInCents, config: ltConfig)
            let formatted = InstallmentCalculator.formatDollars(lowestPayment, currency: currency)

            // "or monthly payments as low as "
            attributed.append(NSAttributedString(
                string: "or\u{00A0}monthly\u{00A0}payments\u{00A0}as\u{00A0}low\u{00A0}as ",
                attributes: baseAttrs
            ))

            // "$XX.XX" in purple bold
            attributed.append(NSAttributedString(
                string: formatted,
                attributes: [
                    .font: UIFont.systemFont(ofSize: style.font.pointSize, weight: .bold),
                    .foregroundColor: SezzleBrand.purple
                ]
            ))

            // " with "
            attributed.append(NSAttributedString(string: "\u{00A0}with ", attributes: baseAttrs))

        case .hidden:
            return attributed
        }

        // Sezzle logo
        if let logo = cachedLogo {
            let attachment = NSTextAttachment()
            let logoHeight = style.font.pointSize * 1.3
            let logoWidth = logoHeight * (logo.size.width / logo.size.height)
            attachment.image = logo
            attachment.bounds = CGRect(x: 0, y: -logoHeight * 0.2, width: logoWidth, height: logoHeight)
            attributed.append(NSAttributedString(attachment: attachment))
        } else {
            attributed.append(NSAttributedString(
                string: "Sezzle",
                attributes: [
                    .font: UIFont.systemFont(ofSize: style.font.pointSize, weight: .bold),
                    .foregroundColor: SezzleBrand.purple
                ]
            ))
        }

        // Info icon
        attributed.append(NSAttributedString(
            string: "\u{00A0}\u{24D8}",
            attributes: [
                .font: UIFont.systemFont(ofSize: style.font.pointSize - 1),
                .foregroundColor: SezzleBrand.purple
            ]
        ))

        // Line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        attributed.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributed.length))

        return attributed
    }
}
