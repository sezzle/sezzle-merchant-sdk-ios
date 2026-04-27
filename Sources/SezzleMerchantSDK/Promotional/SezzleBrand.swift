import UIKit

/// Sezzle brand constants matching the web installment widget.
enum SezzleBrand {
    // MARK: - Colors

    /// Primary purple — installment amounts, active elements.
    static let purple = UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 1) // #8333D4

    /// Dark purple — headings, body text.
    static let darkPurple = UIColor(red: 0x39/255, green: 0x25/255, blue: 0x58/255, alpha: 1) // #392558

    /// Gray — due dates, secondary text.
    static let gray = UIColor(red: 0x5E/255, green: 0x5E/255, blue: 0x5E/255, alpha: 1) // #5E5E5E

    /// Light purple background for cards.
    static let lightPurpleBg = UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 0.05)

    /// Green for first payment / "today" indicator.
    static let green = UIColor(red: 0x00/255, green: 0xB8/255, blue: 0x74/255, alpha: 1) // #00B874

    // MARK: - Logo

    /// Sezzle full-color logo URL.
    static let logoURL = URL(string: "https://media.sezzle.com/branding/2.0/Sezzle_Logo_FullColor.svg")!

    /// Sezzle logo as a PNG for inline use.
    static let logoPngURL = URL(string: "https://media.sezzle.com/branding/2.0/Sezzle_Logo_FullColor.png")!

    // MARK: - Pie Chart SVG Paths

    /// Draw a pie chart showing payment progress (1 of 4, 2 of 4, etc.)
    static func pieChartLayer(step: Int, totalSteps: Int = 4, size: CGFloat) -> CAShapeLayer {
        let center = CGPoint(x: size / 2, y: size / 2)
        let radius = size / 2
        let startAngle = -CGFloat.pi / 2

        // Background circle (light)
        let bgLayer = CAShapeLayer()
        bgLayer.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        bgLayer.fillColor = lightPurpleBg.cgColor

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
    static func pieChartView(step: Int, totalSteps: Int = 4, size: CGFloat = 36) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: size),
            view.heightAnchor.constraint(equalToConstant: size),
        ])
        view.layer.cornerRadius = size / 2
        view.clipsToBounds = true
        let chart = pieChartLayer(step: step, totalSteps: totalSteps, size: size)
        view.layer.addSublayer(chart)
        return view
    }
}
