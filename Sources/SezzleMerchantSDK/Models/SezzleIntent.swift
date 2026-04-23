import Foundation

/// The payment intent for a checkout session.
///
/// - ``auth``: Authorize the payment. You capture it later from your backend.
/// - ``capture``: Automatically capture the payment at checkout completion.
public enum SezzleIntent: String, Sendable {
    /// Authorize only. Capture the payment later via your backend.
    case auth = "AUTH"
    /// Automatically capture the payment at checkout completion.
    case capture = "CAPTURE"
}
