import AuthenticationServices
import UIKit

/// Orchestrates the checkout flow: create session → open browser → handle callback.
@MainActor
final class CheckoutHandler: NSObject {
    private let sessionService: any SessionServiceProtocol
    private let eventLogger: SezzleEventLogger?
    private weak var delegate: (any SezzleCheckoutDelegate)?
    private var authSession: ASWebAuthenticationSession?
    private var presentationContext: DefaultPresentationContext?
    private var orderUUID: String?
    private var sessionUUID: String?
    private var checkoutUUID: String?
    private var checkoutMode: String = ""
    private var resultDelivered = false

    nonisolated static let callbackScheme = "sezzle-sdk"

    init(sessionService: any SessionServiceProtocol, eventLogger: SezzleEventLogger? = nil) {
        self.sessionService = sessionService
        self.eventLogger = eventLogger
    }

    func startCheckout(
        _ checkout: SezzleCheckout,
        from viewController: UIViewController,
        delegate: any SezzleCheckoutDelegate,
        mode: SezzleCheckoutMode
    ) {
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

                guard var checkoutURL = URLComponents(string: response.order.checkoutURL) else {
                    delegate.checkoutDidFail(error: .invalidResponse)
                    return
                }

                // Append isWebView=true for all modes
                var queryItems = checkoutURL.queryItems ?? []
                queryItems.append(URLQueryItem(name: "isWebView", value: "true"))
                checkoutURL.queryItems = queryItems

                guard let finalURL = checkoutURL.url else {
                    delegate.checkoutDidFail(error: .invalidResponse)
                    return
                }

                switch mode {
                case .systemBrowser:
                    openBrowser(url: finalURL, from: viewController)
                case .webView:
                    let webVC = SezzleCheckoutWebViewController(
                        checkoutURL: finalURL,
                        orderUUID: response.order.uuid,
                        delegate: self
                    )
                    viewController.present(webVC, animated: true)
                }
            } catch let error as SezzleError {
                delegate.checkoutDidFail(error: error)
            } catch {
                delegate.checkoutDidFail(error: .networkError(error))
            }
        }
    }

    private func openBrowser(url: URL, from viewController: UIViewController) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: Self.callbackScheme
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
        let path = url.host ?? url.path

        switch path {
        case "checkout":
            let action = url.pathComponents.last
            if action == "confirmed", let orderUUID {
                eventLogger?.log(event: .success, sessionUUID: sessionUUID ?? "", orderUUID: orderUUID, checkoutUUID: checkoutUUID ?? "", mode: checkoutMode)
                deliverResult { $0.checkoutDidComplete(orderUUID: orderUUID) }
            } else if action == "cancelled" {
                eventLogger?.log(event: .cancel, sessionUUID: sessionUUID ?? "", orderUUID: orderUUID ?? "", checkoutUUID: checkoutUUID ?? "", mode: checkoutMode)
                deliverResult { $0.checkoutDidCancel() }
            } else {
                deliverResult { $0.checkoutDidFail(error: .invalidResponse) }
            }
        default:
            deliverResult { $0.checkoutDidFail(error: .invalidResponse) }
        }
    }

    private func extractCheckoutUUID(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString),
              let idParam = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            return nil
        }
        return idParam
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
extension CheckoutHandler: SezzleCheckoutDelegate {
    func checkoutDidComplete(orderUUID: String) {
        eventLogger?.log(event: .success, sessionUUID: sessionUUID ?? "", orderUUID: orderUUID, checkoutUUID: checkoutUUID ?? "", mode: checkoutMode)
        deliverResult { $0.checkoutDidComplete(orderUUID: orderUUID) }
    }

    func checkoutDidCancel() {
        eventLogger?.log(event: .cancel, sessionUUID: sessionUUID ?? "", orderUUID: orderUUID ?? "", checkoutUUID: checkoutUUID ?? "", mode: checkoutMode)
        deliverResult { $0.checkoutDidCancel() }
    }

    func checkoutDidFail(error: SezzleError) {
        eventLogger?.log(event: .failure, sessionUUID: sessionUUID ?? "", orderUUID: orderUUID ?? "", checkoutUUID: checkoutUUID ?? "", mode: checkoutMode, message: error.localizedDescription)
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
