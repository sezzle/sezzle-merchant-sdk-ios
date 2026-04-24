import UIKit
import WebKit

/// Presents the Sezzle checkout in a WKWebView inside the app.
@MainActor
final class SezzleCheckoutWebViewController: UIViewController, WKNavigationDelegate {
    private let checkoutURL: URL
    private let orderUUID: String
    private weak var checkoutDelegate: (any SezzleCheckoutDelegate)?
    private var resultDelivered = false
    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!

    init(checkoutURL: URL, orderUUID: String, delegate: any SezzleCheckoutDelegate) {
        // Append isWebView=true so sezzle-checkout hides its own header
        var components = URLComponents(url: checkoutURL, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "isWebView", value: "true"))
        components?.queryItems = queryItems
        self.checkoutURL = components?.url ?? checkoutURL

        self.orderUUID = orderUUID
        self.checkoutDelegate = delegate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupHeader()
        setupWebView()
        setupLoadingIndicator()
        webView.load(URLRequest(url: checkoutURL))
    }

    private func setupHeader() {
        let header = UIView()
        header.backgroundColor = .systemBackground
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(separator)

        let titleLabel = UILabel()
        titleLabel.text = "sezzle.com"
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(titleLabel)

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .label
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(closeButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            closeButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            separator.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupLoadingIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = SezzleBrand.purple
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        activityIndicator.startAnimating()
    }

    @objc private func closeTapped() {
        deliverResult { $0.checkoutDidFail(error: .browserDismissed) }
        dismiss(animated: true)
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url,
              url.scheme == CheckoutHandler.callbackScheme else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)
        handleCallback(url)
        dismiss(animated: true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        deliverResult { $0.checkoutDidFail(error: .networkError(error)) }
        dismiss(animated: true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).domain == "WebKitErrorDomain", (error as NSError).code == 102 {
            return
        }
        activityIndicator.stopAnimating()
        deliverResult { $0.checkoutDidFail(error: .networkError(error)) }
        dismiss(animated: true)
    }

    // MARK: - Callback handling

    private func handleCallback(_ url: URL) {
        let host = url.host ?? url.path
        switch host {
        case "checkout":
            let action = url.pathComponents.last
            if action == "confirmed" {
                deliverResult { $0.checkoutDidComplete(orderUUID: orderUUID) }
            } else if action == "cancelled" {
                deliverResult { $0.checkoutDidCancel() }
            } else {
                deliverResult { $0.checkoutDidFail(error: .invalidResponse) }
            }
        default:
            deliverResult { $0.checkoutDidFail(error: .invalidResponse) }
        }
    }

    private func deliverResult(_ action: (any SezzleCheckoutDelegate) -> Void) {
        guard !resultDelivered, let delegate = checkoutDelegate else { return }
        resultDelivered = true
        action(delegate)
        checkoutDelegate = nil
    }
}
