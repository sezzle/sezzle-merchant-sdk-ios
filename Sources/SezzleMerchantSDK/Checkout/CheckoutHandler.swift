import AuthenticationServices
import UIKit

/// Orchestrates the checkout flow: create session → open browser → handle callback.
@MainActor
final class CheckoutHandler: NSObject {
    private let sessionService: any SessionServiceProtocol
    private weak var delegate: (any SezzleCheckoutDelegate)?
    private var authSession: ASWebAuthenticationSession?
    private var presentationContext: DefaultPresentationContext?
    private var orderUUID: String?
    private var resultDelivered = false

    nonisolated static let callbackScheme = "sezzle-sdk"

    init(sessionService: any SessionServiceProtocol) {
        self.sessionService = sessionService
    }

    func startCheckout(
        _ checkout: SezzleCheckout,
        from viewController: UIViewController,
        delegate: any SezzleCheckoutDelegate
    ) {
        self.delegate = delegate

        Task {
            do {
                let response = try await sessionService.createSession(checkout: checkout)
                self.orderUUID = response.order.uuid

                guard let checkoutURL = URL(string: response.order.checkoutURL) else {
                    delegate.checkoutDidFail(error: .invalidResponse)
                    return
                }

                openBrowser(url: checkoutURL, from: viewController)
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

        // Retain the presentation context — ASWebAuthenticationSession holds a weak reference
        let context = DefaultPresentationContext(anchor: viewController)
        self.presentationContext = context
        session.presentationContextProvider = viewController as? ASWebAuthenticationPresentationContextProviding ?? context
        session.prefersEphemeralWebBrowserSession = false
        session.start()
        self.authSession = session
    }

    /// Deliver a result exactly once, then clean up.
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

    private func cleanup() {
        authSession = nil
        presentationContext = nil
        orderUUID = nil
        delegate = nil
    }
}

/// Default presentation context when the presenting VC doesn't conform to the protocol.
@MainActor
final class DefaultPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    private weak var anchor: UIViewController?

    init(anchor: UIViewController) {
        self.anchor = anchor
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            // Try the presenting VC's window first, then fall back to the app's key window
            if let window = anchor?.view.window {
                return window
            }
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene,
                   let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                    return window
                }
            }
            // Last resort — should never reach here if the app has a visible window
            return UIWindow()
        }
    }
}
