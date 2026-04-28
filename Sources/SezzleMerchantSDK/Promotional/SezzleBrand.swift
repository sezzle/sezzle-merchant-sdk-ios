import UIKit

/// Sezzle brand constants matching the web installment widget.
enum SezzleBrand {
    // MARK: - Colors

    /// Primary purple — installment amounts, active elements.
    static let purple = UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 1) // #8333D4

    /// Dark purple — headings, body text. Adapts to dark mode.
    /// Light: #382757 (darkPurple100), Dark: #F9F5FD (purpleWhite80)
    static let darkPurple = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0xF9/255, green: 0xF5/255, blue: 0xFD/255, alpha: 1)
            : UIColor(red: 0x38/255, green: 0x27/255, blue: 0x57/255, alpha: 1)
    }

    /// Gray — due dates, secondary text. Adapts to dark mode.
    /// Light: #767676 (darkGray100), Dark: #AEAEAE (gray100)
    static let gray = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0xAE/255, green: 0xAE/255, blue: 0xAE/255, alpha: 1)
            : UIColor(red: 0x76/255, green: 0x76/255, blue: 0x76/255, alpha: 1)
    }

    /// Light purple background for cards. Adapts to dark mode.
    static let lightPurpleBg = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 0.20)
            : UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 0.05)
    }

    /// Green for first payment / "today" indicator.
    static let green = UIColor(red: 0x00/255, green: 0xB8/255, blue: 0x74/255, alpha: 1) // #00B874

    /// Amount text on schedule cards. White in dark mode for contrast on purple card.
    static let scheduleAmount = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .white : purple
    }

    /// Date text on schedule cards. Brighter in dark mode for contrast on purple card.
    static let scheduleDate = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.75, alpha: 1)
            : UIColor(red: 0x76/255, green: 0x76/255, blue: 0x76/255, alpha: 1)
    }

    /// Pie chart background. Semi-transparent white in dark mode for visibility on purple cards.
    static let pieChartBg = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.25)
            : UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 0.05)
    }

    // MARK: - Logo

    /// Sezzle full-color logo URL.
    static let logoURL = URL(string: "https://media.sezzle.com/branding/2.0/Sezzle_Logo_FullColor.svg")!

    /// Sezzle logo as a PNG for inline use.
    static let logoPngURL = URL(string: "https://media.sezzle.com/branding/2.0/Sezzle_Logo_FullColor.png")!

    // MARK: - Pie Chart SVG Paths

    /// Draw a pie chart showing payment progress (1 of 4, 2 of 4, etc.)
    static func pieChartLayer(step: Int, totalSteps: Int = 4, size: CGFloat, isDark: Bool = false) -> CAShapeLayer {
        let center = CGPoint(x: size / 2, y: size / 2)
        let radius = size / 2
        let startAngle = -CGFloat.pi / 2

        // Background circle
        let bgLayer = CAShapeLayer()
        bgLayer.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        bgLayer.fillColor = pieChartBg.resolvedColor(with: UITraitCollection(userInterfaceStyle: isDark ? .dark : .light)).cgColor

        // Filled portion
        let fillLayer = CAShapeLayer()
        let endAngle = startAngle + (CGFloat(step) / CGFloat(totalSteps)) * .pi * 2
        let path = UIBezierPath()
        path.move(to: center)
        path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.close()
        fillLayer.path = path.cgPath
        fillLayer.fillColor = purple.cgColor

        // Container
        let container = CAShapeLayer()
        container.addSublayer(bgLayer)
        container.addSublayer(fillLayer)
        container.frame = CGRect(x: 0, y: 0, width: size, height: size)
        return container
    }

    /// Create a pie chart UIView for a given payment step.
    @MainActor
    static func pieChartView(step: Int, totalSteps: Int = 4, size: CGFloat = 36, isDark: Bool = false) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: size),
            view.heightAnchor.constraint(equalToConstant: size),
        ])
        view.layer.cornerRadius = size / 2
        view.clipsToBounds = true
        let chart = pieChartLayer(step: step, totalSteps: totalSteps, size: size, isDark: isDark)
        view.layer.addSublayer(chart)
        return view
    }
}
