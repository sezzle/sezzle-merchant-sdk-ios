import Foundation

/// Receives callbacks when a Sezzle checkout completes, is cancelled, or fails.
///
/// Implement this protocol to handle the result of ``SezzleSDK/startCheckout(_:from:delegate:)``.
///
/// ```swift
/// extension MyViewController: SezzleCheckoutDelegate {
///     func checkoutDidComplete(orderUUID: String) {
///         // Send orderUUID to your backend for capture
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
    /// - Parameter orderUUID: The Sezzle order UUID. Send this to your backend to capture the payment.
    func checkoutDidComplete(orderUUID: String)

    /// Called when the user cancels the checkout from within the Sezzle checkout page.
    func checkoutDidCancel()

    /// Called when an error occurs during checkout.
    ///
    /// - Parameter error: The error that occurred. See ``SezzleError`` for possible cases.
    func checkoutDidFail(error: SezzleError)
}
