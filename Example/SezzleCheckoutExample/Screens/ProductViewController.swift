import UIKit
import SezzleMerchantSDK

/// Shows multiple products at different price points demonstrating all widget variants.
final class ProductViewController: UIViewController, SezzleCheckoutDelegate {

    // Widget config with long-term enabled for demo (LT kicks in at $250+)
    private let widgetConfig = SezzleWidgetConfig(
        enablePayIn5: true,
        longTermConfig: SezzleLongTermConfig(minPriceInCents: 25_000)
    )

    // Products at different price points showing all widget variants
    private let products: [(name: String, emoji: String, priceInCents: Int, description: String)] = [
        ("Phone Case", "\u{1F4F1}", 1500, "Below $35 min — widget hidden"),
        ("Wireless Earbuds", "\u{1F3A7}", 3999, "$39.99 — 4 payments (under PI5 $50 threshold)"),
        ("Premium Headphones", "\u{1F3A7}", 14999, "$149.99 — 5 payments (PI5 eligible, over $50)"),
        ("Smart Watch", "\u{231A}", 79900, "$799 — long-term monthly payments (over $250)"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sezzle Widget Demo"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        // Server-driven flow demo at the top
        stack.addArrangedSubview(createServerDrivenSection())

        for (index, product) in products.enumerated() {
            let card = createProductCard(product: product, index: index)
            stack.addArrangedSubview(card)
        }
    }

    private func createServerDrivenSection() -> UIView {
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.separator.cgColor

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 8
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        let title = UILabel()
        title.text = "Server-driven flow"
        title.font = .systemFont(ofSize: 18, weight: .bold)
        cardStack.addArrangedSubview(title)

        let desc = UILabel()
        desc.text = "Your backend creates the session via POST /v2/session and supplies its own callback URLs. The SDK opens the URL and reports back via callbackURL. No public key needed on-device."
        desc.font = .systemFont(ofSize: 12)
        desc.textColor = .secondaryLabel
        desc.numberOfLines = 0
        cardStack.addArrangedSubview(desc)

        let buttonRow = UIStackView()
        buttonRow.axis = .horizontal
        buttonRow.spacing = 8
        buttonRow.distribution = .fillEqually

        // System Browser (custom-scheme callbacks — ASWebAuthenticationSession requires it)
        let browserButton = UIButton(type: .system)
        browserButton.setTitle("System Browser", for: .normal)
        browserButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        browserButton.backgroundColor = UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 1)
        browserButton.setTitleColor(.white, for: .normal)
        browserButton.layer.cornerRadius = 10
        browserButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        browserButton.addTarget(self, action: #selector(startServerDrivenSystemBrowserDemo), for: .touchUpInside)
        buttonRow.addArrangedSubview(browserButton)

        // WebView (HTTPS callbacks — universal-link style)
        let webViewButton = UIButton(type: .system)
        webViewButton.setTitle("WebView", for: .normal)
        webViewButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        webViewButton.backgroundColor = .systemBackground
        webViewButton.setTitleColor(UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 1), for: .normal)
        webViewButton.layer.cornerRadius = 10
        webViewButton.layer.borderWidth = 2
        webViewButton.layer.borderColor = UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 1).cgColor
        webViewButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        webViewButton.addTarget(self, action: #selector(startServerDrivenWebViewDemo), for: .touchUpInside)
        buttonRow.addArrangedSubview(webViewButton)

        cardStack.addArrangedSubview(buttonRow)

        return card
    }

    private func createProductCard(product: (name: String, emoji: String, priceInCents: Int, description: String), index: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.separator.cgColor

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 8
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        // Emoji + name row
        let nameRow = UIStackView()
        nameRow.axis = .horizontal
        nameRow.spacing = 8
        let emojiLabel = UILabel()
        emojiLabel.text = product.emoji
        emojiLabel.font = .systemFont(ofSize: 28)
        nameRow.addArrangedSubview(emojiLabel)
        let nameLabel = UILabel()
        nameLabel.text = product.name
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameRow.addArrangedSubview(nameLabel)
        nameRow.addArrangedSubview(UIView()) // spacer
        cardStack.addArrangedSubview(nameRow)

        // Price
        let priceLabel = UILabel()
        priceLabel.text = formatPrice(product.priceInCents)
        priceLabel.font = .systemFont(ofSize: 16, weight: .bold)
        priceLabel.textColor = .label
        cardStack.addArrangedSubview(priceLabel)

        // Description (explains which variant)
        let descLabel = UILabel()
        descLabel.text = product.description
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        cardStack.addArrangedSubview(descLabel)

        // Sezzle promo view
        let promoView = SezzlePromotionalView(
            amountInCents: product.priceInCents,
            widgetConfig: widgetConfig,
            presentingFrom: self
        )
        cardStack.addArrangedSubview(promoView)

        // Checkout buttons row
        let buttonRow = UIStackView()
        buttonRow.axis = .horizontal
        buttonRow.spacing = 8
        buttonRow.distribution = .fillEqually

        // System Browser button
        let browserButton = UIButton(type: .system)
        browserButton.setTitle("System Browser", for: .normal)
        browserButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        browserButton.backgroundColor = UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 1)
        browserButton.setTitleColor(.white, for: .normal)
        browserButton.layer.cornerRadius = 10
        browserButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        browserButton.tag = index
        browserButton.addTarget(self, action: #selector(startCheckoutBrowser(_:)), for: .touchUpInside)
        buttonRow.addArrangedSubview(browserButton)

        // WebView button
        let webViewButton = UIButton(type: .system)
        webViewButton.setTitle("WebView", for: .normal)
        webViewButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        webViewButton.backgroundColor = .systemBackground
        webViewButton.setTitleColor(UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 1), for: .normal)
        webViewButton.layer.cornerRadius = 10
        webViewButton.layer.borderWidth = 2
        webViewButton.layer.borderColor = UIColor(red: 0x83/255, green: 0x33/255, blue: 0xD4/255, alpha: 1).cgColor
        webViewButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        webViewButton.tag = index
        webViewButton.addTarget(self, action: #selector(startCheckoutWebView(_:)), for: .touchUpInside)
        buttonRow.addArrangedSubview(webViewButton)

        cardStack.addArrangedSubview(buttonRow)

        return card
    }

    private func formatPrice(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: dollars)) ?? "$\(String(format: "%.2f", dollars))"
    }

    private func buildCheckout(for index: Int) -> SezzleCheckout {
        let product = products[index]
        return SezzleCheckout(
            customer: SezzleCustomer(
                email: "test@example.com",
                firstName: "Test",
                lastName: "User"
            ),
            order: SezzleOrder(
                referenceId: "example-order-\(Int.random(in: 1000...9999))",
                description: product.name,
                amount: SezzleAmount(amountInCents: product.priceInCents, currency: "USD"),
                items: [
                    SezzleItem(
                        name: product.name,
                        sku: "demo-\(index)",
                        quantity: 1,
                        price: SezzleAmount(amountInCents: product.priceInCents, currency: "USD")
                    )
                ]
            )
        )
    }

    @objc private func startCheckoutBrowser(_ sender: UIButton) {
        let checkout = buildCheckout(for: sender.tag)
        SezzleSDK.shared.startCheckout(checkout, from: self, delegate: self, mode: .systemBrowser)
    }

    @objc private func startCheckoutWebView(_ sender: UIButton) {
        let checkout = buildCheckout(for: sender.tag)
        SezzleSDK.shared.startCheckout(checkout, from: self, delegate: self, mode: .webView)
    }

    /// WebView mode demo: HTTPS callback URLs (universal-link style). Any URL scheme works
    /// in WebView mode — the navigation delegate intercepts before the URL loads.
    @objc private func startServerDrivenWebViewDemo() {
        let orderRef = "poshmark-demo-\(Int.random(in: 1000...9999))"
        let completeURL = URL(string: "https://example.com/sezzle-checkout/done?orderRef=\(orderRef)")!
        let cancelURL = URL(string: "https://example.com/sezzle-checkout/cancelled")!
        runServerDrivenDemo(orderRef: orderRef, completeURL: completeURL, cancelURL: cancelURL, mode: .webView)
    }

    /// System Browser mode demo: custom-scheme callback URLs.
    /// `ASWebAuthenticationSession` requires a custom scheme (won't accept http/https).
    @objc private func startServerDrivenSystemBrowserDemo() {
        let orderRef = "poshmark-demo-\(Int.random(in: 1000...9999))"
        let completeURL = URL(string: "sezzle-example://checkout/done?orderRef=\(orderRef)")!
        let cancelURL = URL(string: "sezzle-example://checkout/cancelled")!
        runServerDrivenDemo(orderRef: orderRef, completeURL: completeURL, cancelURL: cancelURL, mode: .systemBrowser)
    }

    /// Simulates a server-driven integration: the example app pretends to be a backend
    /// by hitting `/v2/session` directly, then hands the URL to the new pass-URL entrypoint.
    /// In production, the network call lives on the merchant's server, not in the app.
    private func runServerDrivenDemo(
        orderRef: String,
        completeURL: URL,
        cancelURL: URL,
        mode: SezzleCheckoutMode
    ) {
        Task {
            do {
                let (checkoutURL, _) = try await createSandboxSession(
                    completeURL: completeURL,
                    cancelURL: cancelURL,
                    referenceId: orderRef
                )
                SezzleSDK.shared.startCheckout(
                    checkoutURL: checkoutURL,
                    completeURL: completeURL,
                    cancelURL: cancelURL,
                    from: self,
                    delegate: self,
                    mode: mode
                )
            } catch {
                let resultVC = ResultViewController(result: .failed(error: .networkError(error)))
                navigationController?.pushViewController(resultVC, animated: true)
            }
        }
    }

    /// Stand-in for "merchant's backend creates the session." Hits sandbox.gateway.sezzle.com
    /// directly with the test public key. Returns (checkoutURL, orderUUID).
    private func createSandboxSession(
        completeURL: URL,
        cancelURL: URL,
        referenceId: String
    ) async throws -> (URL, String) {
        let url = URL(string: "https://sandbox.gateway.sezzle.com/v2/session")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let auth = Data(Secrets.sezzlePublicKey.utf8).base64EncodedString()
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "complete_url": ["href": completeURL.absoluteString, "method": "GET"],
            "cancel_url": ["href": cancelURL.absoluteString, "method": "GET"],
            "customer": [
                "email": "demo@example.com",
                "first_name": "Demo",
                "last_name": "User",
            ],
            "order": [
                "intent": "AUTH",
                "reference_id": referenceId,
                "description": "Server-driven demo",
                "order_amount": ["amount_in_cents": 4999, "currency": "USD"],
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let bodyText = String(data: data, encoding: .utf8) ?? "(non-utf8 body)"

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw NSError(domain: "ServerDrivenDemo", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Session creation failed (\(httpResponse.statusCode)): \(bodyText)"
            ])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let order = json["order"] as? [String: Any],
              let urlString = order["checkout_url"] as? String,
              let url = URL(string: urlString),
              let orderUUID = order["uuid"] as? String else {
            throw NSError(domain: "ServerDrivenDemo", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Could not parse session response: \(bodyText)"
            ])
        }
        return (url, orderUUID)
    }

    // MARK: - SezzleCheckoutDelegate

    func checkoutDidComplete(result: SezzleCheckoutResult) {
        let resultVC: ResultViewController
        if let orderUUID = result.orderUUID {
            // SDK-creates-session flow
            resultVC = ResultViewController(result: .success(orderUUID: orderUUID))
        } else if let callbackURL = result.callbackURL {
            // Server-driven flow
            resultVC = ResultViewController(result: .successWithCallback(callbackURL))
        } else {
            resultVC = ResultViewController(result: .failed(error: .invalidResponse))
        }
        navigationController?.pushViewController(resultVC, animated: true)
    }

    func checkoutDidCancel() {
        let resultVC = ResultViewController(result: .cancelled)
        navigationController?.pushViewController(resultVC, animated: true)
    }

    func checkoutDidFail(error: SezzleError) {
        let resultVC = ResultViewController(result: .failed(error: error))
        navigationController?.pushViewController(resultVC, animated: true)
    }
}
