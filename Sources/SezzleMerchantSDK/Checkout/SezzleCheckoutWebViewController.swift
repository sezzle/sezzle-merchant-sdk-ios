import UIKit
import WebKit

/// Presents the Sezzle checkout in a WKWebView inside the app.
@MainActor
final class SezzleCheckoutWebViewController: UIViewController, WKNavigationDelegate {
    private let checkoutURL: URL
    private let completeURL: URL
    private let cancelURL: URL
    private weak var checkoutDelegate: (any SezzleCheckoutDelegate)?
    private var resultDelivered = false
    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!

    init(
        checkoutURL: URL,
        completeURL: URL,
        cancelURL: URL,
        delegate: any SezzleCheckoutDelegate
    ) {
        // isWebView=true is already appended by CheckoutHandler
        self.checkoutURL = checkoutURL
        self.completeURL = completeURL
        self.cancelURL = cancelURL
        self.checkoutDelegate = delegate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupWebView()
        setupHeader()
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

            closeButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
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

        // Register a scheme handler for the merchant's callback scheme so WKWebView
        // doesn't fail silently when navigating to it. Only register for non-http schemes;
        // http/https schemes are handled by the navigation delegate directly.
        if let scheme = completeURL.scheme?.lowercased(),
           scheme != "http", scheme != "https" {
            config.setURLSchemeHandler(SezzleSchemeHandler(), forURLScheme: scheme)
        }

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        // KVO fallback — observe URL changes to catch any redirect method.
        // Hop to MainActor before reading instance state.
        urlObservation = webView.observe(\.url, options: [.new]) { [weak self] _, change in
            guard let url = change.newValue as? URL else { return }
            Task { @MainActor [weak self] in
                guard let self, self.isCallback(url) else { return }
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
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url, isCallback(url) else {
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
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void
    ) {
        if let url = navigationResponse.response.url, isCallback(url) {
            decisionHandler(.cancel)
            handleCallback(url)
            dismiss(animated: true)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()

        if let url = webView.url, isCallback(url) {
            handleCallback(url)
            dismiss(animated: true)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        activityIndicator.stopAnimating()

        if let failingURL = nsError.userInfo["NSErrorFailingURLKey"] as? URL,
           isCallback(failingURL) {
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
           isCallback(failingURL) {
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

    private func isCallback(_ url: URL) -> Bool {
        CheckoutHandler.matches(url, target: completeURL)
            || CheckoutHandler.matches(url, target: cancelURL)
    }

    private func handleCallback(_ url: URL) {
        if CheckoutHandler.matches(url, target: completeURL) {
            // The wrapping CheckoutHandler will fill in orderUUID for the SDK-creates-session flow
            // (callbackURL stays nil there) or callbackURL for the server-driven flow.
            let result = SezzleCheckoutResult(orderUUID: nil, callbackURL: url)
            deliverResult { $0.checkoutDidComplete(result: result) }
        } else if CheckoutHandler.matches(url, target: cancelURL) {
            deliverResult { $0.checkoutDidCancel() }
        } else {
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

/// Handles custom-scheme requests in WKWebView so they don't fail silently.
/// The actual interception happens in the navigation delegate / KVO observer.
final class SezzleSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        let url = urlSchemeTask.request.url ?? URL(string: "about:blank")!
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {
        // Nothing to clean up
    }
}
