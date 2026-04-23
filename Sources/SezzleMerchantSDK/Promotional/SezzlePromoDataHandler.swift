import UIKit

/// Provides raw promotional message data for custom UI implementations.
///
/// Use this when you want to build your own promotional UI instead of using ``SezzlePromotionalView``.
///
/// ```swift
/// SezzlePromoDataHandler.getMessage(amountInCents: 4999) { attributedString in
///     myLabel.attributedText = attributedString
/// }
/// ```
public enum SezzlePromoDataHandler {
    /// Get a promotional message as an attributed string with the Sezzle logo inline.
    ///
    /// - Parameters:
    ///   - amountInCents: The total order amount in cents.
    ///   - currency: ISO 4217 currency code. Defaults to "USD".
    ///   - style: The visual style. Defaults to `.light`.
    ///   - completion: Called on the main thread with the attributed string.
    ///     Returns an empty string if the amount is not eligible.
    @MainActor
    public static func getMessage(
        amountInCents: Int,
        currency: String = "USD",
        style: SezzlePromotionalStyle = .light,
        completion: @MainActor @Sendable (NSAttributedString) -> Void
    ) {
        guard InstallmentCalculator.isEligible(amountInCents: amountInCents) else {
            completion(NSAttributedString())
            return
        }

        let installments = InstallmentCalculator.installments(amountInCents: amountInCents)
        let formatted = InstallmentCalculator.formatCents(installments[0], currency: currency)
        let message = buildAttributedMessage(installmentAmount: formatted, style: style)
        completion(message)
    }

    /// The bundled Sezzle logo, loaded once from the SDK's resource bundle.
    @MainActor
    private static var cachedLogo: UIImage? = {
        // Load from the SDK's resource bundle (SPM bundles resources automatically)
        if let url = Bundle.module.url(forResource: "sezzle_logo", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }()

    @MainActor
    static func buildAttributedMessage(
        installmentAmount: String,
        style: SezzlePromotionalStyle
    ) -> NSAttributedString {
        let attributed = NSMutableAttributedString()

        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: SezzleBrand.darkPurple
        ]

        // "or 4 interest-free payments of " — use non-breaking spaces to keep this on one line
        attributed.append(NSAttributedString(string: "or\u{00A0}4\u{00A0}interest-free\u{00A0}payments\u{00A0}of ", attributes: baseAttrs))

        // "$XX.XX" in Sezzle purple bold
        attributed.append(NSAttributedString(
            string: installmentAmount,
            attributes: [
                .font: UIFont.systemFont(ofSize: style.font.pointSize, weight: .bold),
                .foregroundColor: SezzleBrand.purple
            ]
        ))

        // " with " — non-breaking before "with" so "$X.XX with" stays together, regular space after to allow break before logo
        attributed.append(NSAttributedString(string: "\u{00A0}with ", attributes: baseAttrs))

        // Sezzle logo as inline image — word joiner prevents break between logo and ⓘ
        if let logo = cachedLogo {
            let attachment = NSTextAttachment()
            let logoHeight = style.font.pointSize * 1.4
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

        return attributed
    }
}
