import UIKit
import WebKit

/// In-app overlay for OAuth provider popups (Sign in with Apple, etc.).
///
/// The Sezzle checkout SPA opens OAuth flows via `window.open`. Apple's
/// `response_mode=web_message` (and Facebook's analogous flow) requires the
/// popup to retain its `window.opener` relationship so the auth result can be
/// posted back to the parent SPA via `postMessage`. Routing the popup out to
/// Safari via `UIApplication.shared.open` breaks that — the system browser
/// has no link to the in-app WebView, and the auth result is silently dropped.
///
/// This controller hosts the popup in-process: a child `WKWebView` whose
/// `WKWebViewConfiguration` is the one WebKit passed us in `createWebViewWith`,
/// which preserves the opener relationship. When the OAuth library calls
/// `window.close()` after handshake completion, `webViewDidClose` fires and
/// we dismiss the overlay.
@MainActor
final class SezzleAuthPopupController: UIViewController, WKUIDelegate {
    let webView: WKWebView

    init(configuration: WKWebViewConfiguration) {
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        webView.uiDelegate = self
        setupHeader()
        setupWebView()
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
        closeButton.accessibilityLabel = "Close"
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
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            separator.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }

    private func setupWebView() {
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
        dismiss(animated: true)
    }

    // MARK: - WKUIDelegate

    /// Apple Sign-In's JS calls `window.close()` on the popup after posting the
    /// auth result back to the opener. WebKit forwards that to us here; we
    /// dismiss our overlay.
    func webViewDidClose(_ webView: WKWebView) {
        dismiss(animated: true)
    }
}
