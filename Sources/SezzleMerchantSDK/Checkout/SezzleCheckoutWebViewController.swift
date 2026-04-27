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

    private var urlObservation: NSKeyValueObservation?

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        // Register our custom scheme so WKWebView recognizes it
        config.setURLSchemeHandler(SezzleSchemeHandler(), forURLScheme: CheckoutHandler.callbackScheme)

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        // KVO fallback — observe URL changes to catch any redirect method
        urlObservation = webView.observe(\.url, options: [.new]) { [weak self] _, change in
            guard let self, let url = change.newValue as? URL,
                  url.scheme == CheckoutHandler.callbackScheme else { return }
            Task { @MainActor in
                self.handleCallback(url)
                self.dismiss(animated: true)
            }
        }

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

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if let url = navigationResponse.response.url,
           url.scheme == CheckoutHandler.callbackScheme {
            decisionHandler(.cancel)
            handleCallback(url)
            dismiss(animated: true)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()

        if let url = webView.url, url.scheme == CheckoutHandler.callbackScheme {
            handleCallback(url)
            dismiss(animated: true)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        activityIndicator.stopAnimating()

        if let failingURL = nsError.userInfo["NSErrorFailingURLKey"] as? URL,
           failingURL.scheme == CheckoutHandler.callbackScheme {
            handleCallback(failingURL)
            dismiss(animated: true)
            return
        }

        deliverResult { $0.checkoutDidFail(error: .networkError(error)) }
        dismiss(animated: true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError

        if let failingURL = nsError.userInfo["NSErrorFailingURLKey"] as? URL
            ?? (nsError.userInfo["NSErrorFailingURLStringKey"] as? String).flatMap(URL.init),
           failingURL.scheme == CheckoutHandler.callbackScheme {
            handleCallback(failingURL)
            dismiss(animated: true)
            return
        }
        if nsError.domain == "WebKitErrorDomain", nsError.code == 102 {
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

/// Handles sezzle-sdk:// scheme requests in WKWebView.
/// When the checkout page navigates to sezzle-sdk://checkout/confirmed,
/// WKWebView calls this handler instead of failing silently.
final class SezzleSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        // We don't actually need to respond — the navigation delegate
        // or KVO observer will handle the URL. Just complete the task.
        let url = urlSchemeTask.request.url ?? URL(string: "sezzle-sdk://unknown")!
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {
        // Nothing to clean up
    }
}
