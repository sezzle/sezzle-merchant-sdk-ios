import AuthenticationServices
import UIKit

/// Orchestrates the checkout flow: optionally create session → open browser → handle callback.
@MainActor
final class CheckoutHandler: NSObject {
    private let sessionService: (any SessionServiceProtocol)?
    private let eventLogger: SezzleEventLogger?
    // Strong (not weak): SezzleSDK wraps the merchant's delegate in a
    // ProgressTrackingDelegate so it can clear the in-progress gate on terminal
    // callbacks. That wrapper is local to startCheckout — if we held it weakly
    // here it would be deallocated before any callback fires, leaving the gate
    // stuck and blocking all subsequent checkouts. cleanup() releases this
    // reference after deliverResult, so no retain cycles.
    private var delegate: (any SezzleCheckoutDelegate)?
    private var authSession: ASWebAuthenticationSession?
    private var presentationContext: DefaultPresentationContext?
    private var orderUUID: String?
    private var sessionUUID: String?
    private var checkoutUUID: String?
    private var checkoutMode: String = ""
    private var resultDelivered = false

    // Per-checkout callback URLs. For the SDK-creates-session flow, these default to
    // the hardcoded sezzle-sdk:// URLs. For the server-driven flow, the merchant supplies them.
    private var completeURL: URL = CheckoutHandler.defaultCompleteURL
    private var cancelURL: URL = CheckoutHandler.defaultCancelURL

    nonisolated static let callbackScheme = "sezzle-sdk"
    nonisolated static let defaultCompleteURL = URL(string: "sezzle-sdk://checkout/confirmed")!
    nonisolated static let defaultCancelURL = URL(string: "sezzle-sdk://checkout/cancelled")!

    init(sessionService: (any SessionServiceProtocol)?, eventLogger: SezzleEventLogger? = nil) {
        self.sessionService = sessionService
        self.eventLogger = eventLogger
    }

    // MARK: - SDK-creates-session flow

    func startCheckout(
        _ checkout: SezzleCheckout,
        from viewController: UIViewController,
        delegate: any SezzleCheckoutDelegate,
        mode: SezzleCheckoutMode
    ) {
        guard let sessionService else {
            delegate.checkoutDidFail(error: .notConfigured)
            return
        }

        self.delegate = delegate
        self.checkoutMode = mode == .webView ? "webview" : "system_browser"

        eventLogger?.log(event: .popupCreated, mode: checkoutMode, message: "checkout initiated")

        Task {
            do {
                let response = try await sessionService.createSession(checkout: checkout)
                self.orderUUID = response.order.uuid
                self.sessionUUID = response.uuid
                self.checkoutUUID = extractCheckoutUUID(from: response.order.checkoutURL)

                eventLogger?.log(
                    event: .loaded,
                    sessionUUID: response.uuid,
                    orderUUID: response.order.uuid,
                    checkoutUUID: self.checkoutUUID ?? "",
                    mode: checkoutMode
                )

                guard let finalURL = appendIsWebViewParam(to: response.order.checkoutURL) else {
                    delegate.checkoutDidFail(error: .invalidResponse)
                    return
                }

                presentCheckout(
                    url: finalURL,
                    completeURL: Self.defaultCompleteURL,
                    cancelURL: Self.defaultCancelURL,
                    from: viewController,
                    mode: mode
                )
            } catch let error as SezzleError {
                delegate.checkoutDidFail(error: error)
            } catch {
                delegate.checkoutDidFail(error: .networkError(error))
            }
        }
    }

    // MARK: - Server-driven (pass-URL) flow

    func startCheckout(
        checkoutURL: URL,
        completeURL: URL,
        cancelURL: URL,
        from viewController: UIViewController,
        delegate: any SezzleCheckoutDelegate,
        mode: SezzleCheckoutMode
    ) {
        self.delegate = delegate
        self.checkoutMode = mode == .webView ? "webview" : "system_browser"
        // orderUUID stays nil — the merchant has it server-side, we don't.

        let finalURL = appendIsWebViewParam(to: checkoutURL.absoluteString) ?? checkoutURL

        presentCheckout(
            url: finalURL,
            completeURL: completeURL,
            cancelURL: cancelURL,
            from: viewController,
            mode: mode
        )
    }

    // MARK: - Shared presentation

    private func presentCheckout(
        url: URL,
        completeURL: URL,
        cancelURL: URL,
        from viewController: UIViewController,
        mode: SezzleCheckoutMode
    ) {
        self.completeURL = completeURL
        self.cancelURL = cancelURL

        switch mode {
        case .systemBrowser:
            openBrowser(url: url, from: viewController)
        case .webView:
            let webVC = SezzleCheckoutWebViewController(
                checkoutURL: url,
                completeURL: completeURL,
                cancelURL: cancelURL,
                delegate: self
            )
            viewController.present(webVC, animated: true)
        }
    }

    private func openBrowser(url: URL, from viewController: UIViewController) {
        // ASWebAuthenticationSession's callbackURLScheme must be a custom scheme
        // (not http/https). For the existing flow this is always "sezzle-sdk".
        // For the server-driven flow it's whatever scheme the merchant chose for completeURL.
        let callbackURLScheme = completeURL.scheme ?? Self.callbackScheme

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackURLScheme
        ) { [weak self] callbackURL, error in
            guard let self, !self.resultDelivered else { return }

            if let error = error as? ASWebAuthenticationSessionError,
               error.code == .canceledLogin {
                self.deliverResult { $0.checkoutDidFail(error: .browserDismissed) }
                return
            }

            if let error {
                self.deliverResult { $0.checkoutDidFail(error: .networkError(error)) }
                return
            }

            guard let callbackURL else {
                self.deliverResult { $0.checkoutDidFail(error: .invalidResponse) }
                return
            }

            self.handleCallback(callbackURL)
        }

        let context = DefaultPresentationContext(anchor: viewController)
        self.presentationContext = context
        session.presentationContextProvider = viewController as? ASWebAuthenticationPresentationContextProviding ?? context
        session.prefersEphemeralWebBrowserSession = false
        session.start()
        self.authSession = session
    }

    private func deliverResult(_ action: (any SezzleCheckoutDelegate) -> Void) {
        guard !resultDelivered, let delegate else { return }
        resultDelivered = true
        action(delegate)
        cleanup()
    }

    private func handleCallback(_ url: URL) {
        if Self.matches(url, target: completeURL) {
            eventLogger?.log(
                event: .success,
                sessionUUID: sessionUUID ?? "",
                orderUUID: orderUUID ?? "",
                checkoutUUID: checkoutUUID ?? "",
                mode: checkoutMode
            )
            let result = SezzleCheckoutResult(
                orderUUID: orderUUID,
                callbackURL: orderUUID == nil ? url : nil
            )
            deliverResult { $0.checkoutDidComplete(result: result) }
        } else if Self.matches(url, target: cancelURL) {
            eventLogger?.log(
                event: .cancel,
                sessionUUID: sessionUUID ?? "",
                orderUUID: orderUUID ?? "",
                checkoutUUID: checkoutUUID ?? "",
                mode: checkoutMode
            )
            deliverResult { $0.checkoutDidCancel() }
        } else {
            deliverResult { $0.checkoutDidFail(error: .invalidResponse) }
        }
    }

    /// Matches if `url` shares scheme + host + path with `target`. Query/fragment may differ.
    nonisolated static func matches(_ url: URL, target: URL) -> Bool {
        url.scheme?.lowercased() == target.scheme?.lowercased()
            && url.host?.lowercased() == target.host?.lowercased()
            && url.path == target.path
    }

    private func extractCheckoutUUID(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString),
              let idParam = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            return nil
        }
        return idParam
    }

    private func appendIsWebViewParam(to urlString: String) -> URL? {
        guard var components = URLComponents(string: urlString) else { return nil }
        var queryItems = components.queryItems ?? []
        if !queryItems.contains(where: { $0.name == "isWebView" }) {
            queryItems.append(URLQueryItem(name: "isWebView", value: "true"))
        }
        components.queryItems = queryItems
        return components.url
    }

    private func cleanup() {
        authSession = nil
        presentationContext = nil
        orderUUID = nil
        sessionUUID = nil
        checkoutUUID = nil
        delegate = nil
    }
}

// MARK: - SezzleCheckoutDelegate conformance for WebView wrapper
//
// The WebViewController fires `checkoutDidComplete(result:)` with `callbackURL` set
// (since it doesn't know about session UUIDs). This wrapper rewrites the result
// to match the calling flow:
//   - SDK-creates-session flow → result with orderUUID, callbackURL nil
//   - Server-driven flow       → pass through with callbackURL
extension CheckoutHandler: SezzleCheckoutDelegate {
    func checkoutDidComplete(result: SezzleCheckoutResult) {
        let finalResult: SezzleCheckoutResult
        if let orderUUID {
            finalResult = SezzleCheckoutResult(orderUUID: orderUUID, callbackURL: nil)
        } else {
            finalResult = result
        }
        eventLogger?.log(
            event: .success,
            sessionUUID: sessionUUID ?? "",
            orderUUID: finalResult.orderUUID ?? "",
            checkoutUUID: checkoutUUID ?? "",
            mode: checkoutMode
        )
        deliverResult { $0.checkoutDidComplete(result: finalResult) }
    }

    func checkoutDidCancel() {
        eventLogger?.log(
            event: .cancel,
            sessionUUID: sessionUUID ?? "",
            orderUUID: orderUUID ?? "",
            checkoutUUID: checkoutUUID ?? "",
            mode: checkoutMode
        )
        deliverResult { $0.checkoutDidCancel() }
    }

    func checkoutDidFail(error: SezzleError) {
        eventLogger?.log(
            event: .failure,
            sessionUUID: sessionUUID ?? "",
            orderUUID: orderUUID ?? "",
            checkoutUUID: checkoutUUID ?? "",
            mode: checkoutMode,
            message: error.localizedDescription
        )
        deliverResult { $0.checkoutDidFail(error: error) }
    }
}

@MainActor
final class DefaultPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    private weak var anchor: UIViewController?

    init(anchor: UIViewController) {
        self.anchor = anchor
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            if let window = anchor?.view.window {
                return window
            }
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene,
                   let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                    return window
                }
            }
            return UIWindow()
        }
    }
}
