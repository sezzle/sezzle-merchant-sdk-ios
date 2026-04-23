import UIKit

/// Visual style for Sezzle promotional messaging.
///
/// Use the built-in `.light` or `.dark` presets, or create a custom style.
///
/// ```swift
/// let promoView = SezzlePromotionalView(
///     amountInCents: 4999,
///     style: .dark,
///     presentingFrom: self
/// )
/// ```
public struct SezzlePromotionalStyle: @unchecked Sendable {
    /// Dark text on light backgrounds.
    public static let light = SezzlePromotionalStyle(
        logoVariant: .dark,
        font: .systemFont(ofSize: 14, weight: .regular),
        textColor: .label
    )

    /// Light text on dark backgrounds.
    public static let dark = SezzlePromotionalStyle(
        logoVariant: .light,
        font: .systemFont(ofSize: 14, weight: .regular),
        textColor: .white
    )

    /// Which logo variant to display.
    public var logoVariant: SezzleLogoVariant
    /// Font for the promotional message text.
    public var font: UIFont
    /// Color for the promotional message text.
    public var textColor: UIColor

    public init(logoVariant: SezzleLogoVariant, font: UIFont, textColor: UIColor) {
        self.logoVariant = logoVariant
        self.font = font
        self.textColor = textColor
    }
}

/// Logo color variant for promotional messaging.
public enum SezzleLogoVariant: Sendable {
    /// Dark logo for light backgrounds.
    case dark
    /// Light logo for dark backgrounds.
    case light
}
