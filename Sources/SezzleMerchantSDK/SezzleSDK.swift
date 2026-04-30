import UIKit

/// The main entry point for the Sezzle Merchant SDK.
///
/// Configure the SDK once at app startup, then start checkouts from anywhere in your app.
///
/// ## Quick Start
///
/// ```swift
/// // 1. Configure in AppDelegate
/// SezzleSDK.shared.configure(
///     publicKey: "sz_pub_...",
///     environment: .sandbox
/// )
///
/// // 2. Start checkout
/// let checkout = SezzleCheckout(
///     customer: SezzleCustomer(email: "jane@example.com"),
///     order: SezzleOrder(
///         referenceId: "order-123",
///         amount: SezzleAmount(amountInCents: 4999, currency: "USD")
///     )
/// )
/// SezzleSDK.shared.startCheckout(checkout, from: self, delegate: self)
/// ```
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
    /// Call this once at app startup (e.g., in `AppDelegate.didFinishLaunchingWithOptions`
    /// or your SwiftUI `App.init`), before making any other SDK calls.
    ///
    /// - Parameters:
    ///   - publicKey: Your Sezzle public key (starts with `sz_pub_...`).
    ///     Get this from the Sezzle Merchant Dashboard → Settings → API Keys.
    ///   - environment: `.sandbox` for development/testing, `.production` for live transactions.
    public func configure(publicKey: String, environment: SezzleEnvironment = .production) {
        self.publicKey = publicKey
        self.environment = environment
    }

    /// Start a Sezzle checkout.
    ///
    /// Opens the Sezzle checkout in a browser. When the user completes,
    /// cancels, or encounters an error, the appropriate delegate method is called.
    ///
    /// - Parameters:
    ///   - checkout: The customer and order data for this checkout.
    ///   - viewController: The view controller to present the checkout from.
    ///   - delegate: Receives checkout completion, cancellation, or error callbacks.
    ///   - mode: How the checkout is presented. Defaults to `.systemBrowser`.
    ///
    /// The delegate's ``SezzleCheckoutDelegate/checkoutDidComplete(orderUUID:)`` returns
    /// the Sezzle order UUID. Send this to your backend to capture the payment via
    /// `POST /v2/order/{uuid}/capture`.
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

    /// Whether the SDK has been configured.
    public var isConfigured: Bool {
        publicKey != nil && environment != nil
    }
}
