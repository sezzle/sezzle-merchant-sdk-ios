import Foundation

/// Receives callbacks when a Sezzle checkout completes, is cancelled, or fails.
///
/// Implement this protocol to handle the result of either checkout entrypoint.
///
/// ```swift
/// extension MyViewController: SezzleCheckoutDelegate {
///     func checkoutDidComplete(result: SezzleCheckoutResult) {
///         if let orderUUID = result.orderUUID {
///             // SDK-creates-session flow — capture via your backend
///         } else if let callbackURL = result.callbackURL {
///             // Server-driven flow — read query params you encoded
///         }
///     }
///     func checkoutDidCancel() {
///         // User cancelled — return to cart
///     }
///     func checkoutDidFail(error: SezzleError) {
///         // Show error to user
///     }
/// }
/// ```
@MainActor
public protocol SezzleCheckoutDelegate: AnyObject {
    /// Called when the user successfully completes checkout.
    ///
    /// - Parameter result: See ``SezzleCheckoutResult`` for which fields are populated by which flow.
    func checkoutDidComplete(result: SezzleCheckoutResult)

    /// Called when the user cancels the checkout from within the Sezzle checkout page.
    func checkoutDidCancel()

    /// Called when an error occurs during checkout.
    ///
    /// - Parameter error: The error that occurred. See ``SezzleError`` for possible cases.
    func checkoutDidFail(error: SezzleError)
}
