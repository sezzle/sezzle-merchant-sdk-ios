import UIKit
import SezzleMerchantSDK

/// Shows the result of a checkout: success (orderUUID), cancelled, or error.
///
/// Demonstrates how to handle all three `SezzleCheckoutDelegate` callbacks.
final class ResultViewController: UIViewController {

    enum CheckoutResult {
        case success(orderUUID: String)
        case successWithCallback(URL)
        case cancelled
        case failed(error: SezzleError)
    }

    private let result: CheckoutResult

    init(result: CheckoutResult) {
        self.result = result
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        setupUI()
    }

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])

        let iconLabel = UILabel()
        iconLabel.font = .systemFont(ofSize: 60)

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let detailLabel = UILabel()
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textColor = .secondaryLabel
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        switch result {
        case .success(let orderUUID):
            title = "Success"
            iconLabel.text = "✅"
            titleLabel.text = "Checkout Complete!"
            detailLabel.text = "Order UUID:\n\(orderUUID)\n\nSend this to your backend to capture the payment."

        case .successWithCallback(let callbackURL):
            title = "Success"
            iconLabel.text = "✅"
            titleLabel.text = "Server-Driven Checkout Complete!"
            titleLabel.textColor = .systemGreen
            let queryParams = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                .queryItems?
                .map { "\($0.name) = \($0.value ?? "")" }
                .joined(separator: "\n") ?? "(none)"
            detailLabel.text = "Callback URL:\n\(callbackURL.absoluteString)\n\nQuery Parameters:\n\(queryParams)\n\nLook up the order in your backend (you encoded its ID in your complete_url) and call POST /v2/order/{uuid}/capture."

        case .cancelled:
            title = "Cancelled"
            iconLabel.text = "🚫"
            titleLabel.text = "Checkout Cancelled"
            detailLabel.text = "The customer cancelled the checkout."

        case .failed(let error):
            title = "Error"
            iconLabel.text = "❌"
            titleLabel.text = "Checkout Failed"
            detailLabel.text = error.localizedDescription
        }

        stack.addArrangedSubview(iconLabel)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(detailLabel)

        // Back button
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back to Product", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        stack.addArrangedSubview(backButton)
    }

    @objc private func goBack() {
        navigationController?.popToRootViewController(animated: true)
    }
}
