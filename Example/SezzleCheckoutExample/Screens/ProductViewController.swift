import UIKit
import SezzleMerchantSDK

/// Shows a product with a Sezzle promotional message and a "Pay with Sezzle" button.
///
/// Demonstrates how to:
/// - Embed `SezzlePromotionalView` on a product page
/// - Build a `SezzleCheckout` from product data
/// - Start the checkout flow
final class ProductViewController: UIViewController, SezzleCheckoutDelegate {

    // Sample product data
    private let productName = "Premium Wireless Headphones"
    private let productPriceInCents = 4999 // $49.99
    private let productCurrency = "USD"

    private var promoView: SezzlePromotionalView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Product"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        // Product image placeholder
        let imageView = UIView()
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        let imageLabel = UILabel()
        imageLabel.text = "🎧"
        imageLabel.font = .systemFont(ofSize: 60)
        imageLabel.textAlignment = .center
        imageLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(imageLabel)
        NSLayoutConstraint.activate([
            imageLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            imageLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
        ])
        stack.addArrangedSubview(imageView)

        // Product name
        let nameLabel = UILabel()
        nameLabel.text = productName
        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.numberOfLines = 0
        stack.addArrangedSubview(nameLabel)

        // Product price
        let priceLabel = UILabel()
        priceLabel.text = formatPrice(productPriceInCents)
        priceLabel.font = .systemFont(ofSize: 20, weight: .bold)
        priceLabel.textColor = .label
        stack.addArrangedSubview(priceLabel)

        // Sezzle promotional view
        promoView = SezzlePromotionalView(
            amountInCents: productPriceInCents,
            currency: productCurrency,
            presentingFrom: self
        )
        stack.addArrangedSubview(promoView)

        // Spacer
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        stack.addArrangedSubview(spacer)

        // Pay with Sezzle button
        let checkoutButton = UIButton(type: .system)
        checkoutButton.setTitle("Pay with Sezzle", for: .normal)
        checkoutButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        checkoutButton.backgroundColor = UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 1)
        checkoutButton.setTitleColor(.white, for: .normal)
        checkoutButton.layer.cornerRadius = 12
        checkoutButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        checkoutButton.addTarget(self, action: #selector(startCheckout), for: .touchUpInside)
        stack.addArrangedSubview(checkoutButton)
    }

    private func formatPrice(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = productCurrency
        return formatter.string(from: NSNumber(value: dollars)) ?? "$\(String(format: "%.2f", dollars))"
    }

    @objc private func startCheckout() {
        // Build the checkout from product data
        let checkout = SezzleCheckout(
            customer: SezzleCustomer(
                email: "test@example.com",
                firstName: "Test",
                lastName: "User"
            ),
            order: SezzleOrder(
                referenceId: "example-order-\(Int.random(in: 1000...9999))",
                description: productName,
                amount: SezzleAmount(amountInCents: productPriceInCents, currency: productCurrency),
                items: [
                    SezzleItem(
                        name: productName,
                        sku: "headphones-premium-001",
                        quantity: 1,
                        price: SezzleAmount(amountInCents: productPriceInCents, currency: productCurrency)
                    )
                ]
            )
        )

        // Start the Sezzle checkout — opens a secure browser
        SezzleSDK.shared.startCheckout(checkout, from: self, delegate: self)
    }

    // MARK: - SezzleCheckoutDelegate

    func checkoutDidComplete(orderUUID: String) {
        let resultVC = ResultViewController(
            result: .success(orderUUID: orderUUID)
        )
        navigationController?.pushViewController(resultVC, animated: true)
    }

    func checkoutDidCancel() {
        let resultVC = ResultViewController(result: .cancelled)
        navigationController?.pushViewController(resultVC, animated: true)
    }

    func checkoutDidFail(error: SezzleError) {
        let resultVC = ResultViewController(
            result: .failed(error: error)
        )
        navigationController?.pushViewController(resultVC, animated: true)
    }
}
