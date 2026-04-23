import Foundation

/// Errors that can occur during Sezzle SDK operations.
///
/// Handle these in your ``SezzleCheckoutDelegate/checkoutDidFail(error:)`` callback.
public enum SezzleError: Error, Sendable {
    /// The SDK has not been configured. Call ``SezzleSDK/configure(publicKey:environment:)`` first.
    case notConfigured
    /// A network error occurred (no connectivity, timeout, DNS failure, etc.).
    case networkError(any Error & Sendable)
    /// The Sezzle API returned a non-success response.
    case apiError(statusCode: Int, message: String)
    /// The user dismissed the checkout browser before completing.
    case browserDismissed
    /// The API response could not be parsed.
    case invalidResponse
}

extension SezzleError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Sezzle SDK is not configured. Call SezzleSDK.shared.configure() before starting checkout."
        case .networkError(let underlying):
            "Network error: \(underlying.localizedDescription)"
        case .apiError(let statusCode, let message):
            "Sezzle API error (\(statusCode)): \(message)"
        case .browserDismissed:
            "Checkout was dismissed before completion."
        case .invalidResponse:
            "Could not parse the response from Sezzle."
        }
    }
}
