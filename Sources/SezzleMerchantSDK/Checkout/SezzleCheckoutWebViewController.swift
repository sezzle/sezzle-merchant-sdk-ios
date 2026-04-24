import UIKit
import WebKit

/// Presents the Sezzle checkout in a WKWebView inside the app.
///
/// Used when `SezzleCheckoutMode.webView` is specified. Intercepts the
/// `sezzle-sdk://` callback URL via `WKNavigationDelegate` to detect
/// checkout completion, cancellation, or errors.
@MainActor
final class SezzleCheckoutWebViewController: UIViewController, WKNavigationDelegate {
    private let checkoutURL: URL
    private let orderUUID: String
    private weak var checkoutDelegate: (any SezzleCheckoutDelegate)?
    private var resultDelivered = false
    private var webView: WKWebView!

    init(checkoutURL: URL, orderUUID: String, delegate: any SezzleCheckoutDelegate) {
        self.checkoutURL = checkoutURL
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
        setupNavigationBar()
        setupWebView()
        webView.load(URLRequest(url: checkoutURL))
    }

    private func setupNavigationBar() {
        let nav = UINavigationBar()
        nav.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nav)

        let navItem = UINavigationItem(title: "Sezzle Checkout")
        navItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        nav.items = [navItem]

        NSLayoutConstraint.activate([
            nav.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            nav.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nav.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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

        // Intercept the sezzle-sdk:// callback
        decisionHandler(.cancel)
        handleCallback(url)
        dismiss(animated: true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        deliverResult { $0.checkoutDidFail(error: .networkError(error)) }
        dismiss(animated: true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Ignore errors from intercepting the sezzle-sdk:// scheme
        if (error as NSError).domain == "WebKitErrorDomain", (error as NSError).code == 102 {
            return
        }
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
