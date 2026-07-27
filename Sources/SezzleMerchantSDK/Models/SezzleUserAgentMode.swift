import Foundation

/// How the merchant surface hosts the Sezzle checkout page.
///
/// Sent as `order.checkout_mode` on `POST /v2/session` and recorded on the
/// checkout as `sezzle_user_agent_mode`. Checkout uses it to decide how to
/// signal completion back to whatever embedded it.
///
/// Distinct from ``SezzleCheckoutMode``, which controls how *this SDK*
/// presents checkout (system browser vs. in-app WebView).
///
/// Defaults to ``redirect`` on ``SezzleOrder``, which is correct for both of
/// this SDK's presentation modes — completion is detected from the redirect to
/// your complete/cancel URL. Override it only if you have a reason to.
public enum SezzleUserAgentMode: String, Sendable {
    /// Checkout signals completion by redirecting to the complete/cancel URL.
    case redirect
    /// Checkout is embedded in an iframe and posts a message to the parent frame.
    case iframe
    /// Checkout runs in a popup window and posts a message to its opener.
    case popup
}
