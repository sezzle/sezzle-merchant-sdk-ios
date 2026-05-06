import Foundation

/// The result of a successful Sezzle checkout, delivered via
/// ``SezzleCheckoutDelegate/checkoutDidComplete(result:)``.
///
/// Two flows produce different fields:
///
/// - **SDK-creates-session flow** (``SezzleSDK/startCheckout(_:from:delegate:mode:)``):
///   `orderUUID` is populated; `callbackURL` is `nil`.
///
/// - **Server-driven flow** (``SezzleSDK/startCheckout(checkoutURL:completeURL:cancelURL:from:delegate:mode:)``):
///   `callbackURL` is populated with the full URL the user landed on (so you can
///   read query params you encoded in your `complete_url`); `orderUUID` is `nil`
///   because your backend already has it from the session-creation response.
public struct SezzleCheckoutResult: Sendable {
    /// The Sezzle order UUID, populated only by the SDK-creates-session flow.
    /// Send this to your backend to capture the payment via `POST /v2/order/{uuid}/capture`.
    public let orderUUID: String?

    /// The full callback URL the user landed on, populated only by the server-driven flow.
    /// Read query parameters here to recover any state you encoded in your `complete_url`.
    public let callbackURL: URL?

    public init(orderUUID: String? = nil, callbackURL: URL? = nil) {
        self.orderUUID = orderUUID
        self.callbackURL = callbackURL
    }
}
