import UIKit

/// The main entry point for the Sezzle Merchant SDK.
///
/// Two checkout flows are supported:
///
/// **SDK-creates-session flow** — call ``configure(publicKey:environment:)`` once at app
/// startup, then call ``startCheckout(_:from:delegate:mode:)`` with a ``SezzleCheckout``
/// payload. The SDK creates the session via Sezzle's API and presents checkout.
///
/// **Server-driven flow** — your backend creates the session via `POST /v2/session`
/// directly, then call ``startCheckout(checkoutURL:completeURL:cancelURL:from:delegate:mode:)``
/// with the response data. No public key on-device, no `configure(publicKey:)` required.
@MainActor
public final class SezzleSDK {
    /// The shared SDK instance.
    public static let shared = SezzleSDK()

    private var publicKey: String?
    private var environment: SezzleEnvironment?
    private var checkoutHandler: CheckoutHandler?

    private init() {}

    /// Configure the SDK with your Sezzle public key.
    ///
    /// Required only for the SDK-creates-session flow. The server-driven entrypoint
    /// (``startCheckout(checkoutURL:completeURL:cancelURL:from:delegate:mode:)``) works
    /// without ever calling `configure`.
    ///
    /// - Parameters:
    ///   - publicKey: Your Sezzle public key (starts with `sz_pub_...`).
    ///     Get this from the Sezzle Merchant Dashboard → Settings → API Keys.
    ///   - environment: `.sandbox` for development/testing, `.production` for live transactions.
    public func configure(publicKey: String, environment: SezzleEnvironment = .production) {
        self.publicKey = publicKey
        self.environment = environment
    }

    /// Start a Sezzle checkout — SDK creates the session.
    ///
    /// Requires ``configure(publicKey:environment:)`` to have been called.
    ///
    /// - Parameters:
    ///   - checkout: The customer and order data for this checkout.
    ///   - viewController: The view controller to present the checkout from.
    ///   - delegate: Receives checkout completion, cancellation, or error callbacks.
    ///   - mode: How the checkout is presented. Defaults to `.systemBrowser`.
    ///
    /// On success, ``SezzleCheckoutDelegate/checkoutDidComplete(result:)`` is called with
    /// `result.orderUUID` populated. Send that UUID to your backend to capture the payment
    /// via `POST /v2/order/{uuid}/capture`.
    public func startCheckout(
        _ checkout: SezzleCheckout,
        from viewController: UIViewController,
        delegate: any SezzleCheckoutDelegate,
        mode: SezzleCheckoutMode = .systemBrowser
    ) {
        guard let publicKey, let environment else {
            delegate.checkoutDidFail(error: .notConfigured)
            return
        }

        let httpClient = HTTPClient(publicKey: publicKey, environment: environment)
        let sessionService = SessionService(httpClient: httpClient)
        let eventLogger = SezzleEventLogger(publicKey: publicKey, environment: environment)
        let handler = CheckoutHandler(sessionService: sessionService, eventLogger: eventLogger)
        self.checkoutHandler = handler
        handler.startCheckout(checkout, from: viewController, delegate: delegate, mode: mode)
    }

    /// Start a Sezzle checkout — your backend already created the session.
    ///
    /// Use this when your server creates the Sezzle session via `POST /v2/session` directly
    /// (e.g. to keep your private key off-device). Pass the `order.checkout_url` from the
    /// session response, plus the same `complete_url.href` and `cancel_url.href` your server
    /// supplied in the request — the SDK intercepts navigation to those URLs and dispatches
    /// the corresponding delegate method.
    ///
    /// Does NOT require ``configure(publicKey:environment:)`` to have been called.
    ///
    /// On success, ``SezzleCheckoutDelegate/checkoutDidComplete(result:)`` is called with
    /// `result.callbackURL` populated — read query parameters there to recover any state
    /// you encoded in your `complete_url`. `result.orderUUID` is `nil` because your backend
    /// already has it from the session-creation response.
    ///
    /// - Important: For `.systemBrowser` mode, `completeURL` and `cancelURL` must use a
    ///   **custom URL scheme** (not `http`/`https`) — `ASWebAuthenticationSession` requires it.
    ///   `.webView` mode supports any scheme.
    ///
    /// - Important: On Android, merchants using `.systemBrowser` mode with a custom callback
    ///   scheme must register an intent-filter for that scheme in their own `AndroidManifest.xml`.
    ///   This iOS API has no equivalent platform requirement.
    ///
    /// - Parameters:
    ///   - checkoutURL: The `order.checkout_url` from your `POST /v2/session` response.
    ///   - completeURL: The same URL you passed as `complete_url.href` in the session request.
    ///   - cancelURL: The same URL you passed as `cancel_url.href` in the session request.
    ///   - viewController: The view controller to present the checkout from.
    ///   - delegate: Receives checkout completion, cancellation, or error callbacks.
    ///   - mode: How the checkout is presented. Defaults to `.systemBrowser`.
    public func startCheckout(
        checkoutURL: URL,
        completeURL: URL,
        cancelURL: URL,
        from viewController: UIViewController,
        delegate: any SezzleCheckoutDelegate,
        mode: SezzleCheckoutMode = .systemBrowser
    ) {
        #if DEBUG
        validate(
            checkoutURL: checkoutURL,
            completeURL: completeURL,
            cancelURL: cancelURL,
            mode: mode
        )
        #endif

        let handler = CheckoutHandler(sessionService: nil, eventLogger: nil)
        self.checkoutHandler = handler
        handler.startCheckout(
            checkoutURL: checkoutURL,
            completeURL: completeURL,
            cancelURL: cancelURL,
            from: viewController,
            delegate: delegate,
            mode: mode
        )
    }

    /// Whether the SDK has been configured.
    ///
    /// Required for the SDK-creates-session flow. Not required for the server-driven flow.
    public var isConfigured: Bool {
        publicKey != nil && environment != nil
    }

    #if DEBUG
    private func validate(
        checkoutURL: URL,
        completeURL: URL,
        cancelURL: URL,
        mode: SezzleCheckoutMode
    ) {
        if let host = checkoutURL.host?.lowercased(),
           !host.hasSuffix("sezzle.com") {
            print("⚠️ [SezzleSDK] checkoutURL host '\(host)' is not a sezzle.com domain. Are you sure this is right?")
        }
        if mode == .systemBrowser {
            for (label, url) in [("completeURL", completeURL), ("cancelURL", cancelURL)] {
                if let scheme = url.scheme?.lowercased(),
                   scheme == "http" || scheme == "https" {
                    print("⚠️ [SezzleSDK] \(label) uses '\(scheme)' which won't work with .systemBrowser mode (ASWebAuthenticationSession requires a custom scheme). Use .webView mode or a custom scheme.")
                }
            }
        }
    }
    #endif
}
