import Foundation

/// How the Sezzle checkout is presented to the user.
public enum SezzleCheckoutMode: Sendable {
    /// Opens checkout in the system browser (ASWebAuthenticationSession).
    ///
    /// This is the **recommended** mode:
    /// - Secure: runs in a separate browser process, not the app's process
    /// - Shares cookies with Safari (faster login if already signed into Sezzle)
    /// - Cannot be manipulated by the merchant app
    case systemBrowser

    /// Opens checkout in a WKWebView embedded inside the app.
    ///
    /// Use this when you want the user to stay inside your app during checkout.
    /// Trade-offs vs system browser:
    /// - No cookie sharing with Safari (user logs in every time)
    /// - Runs inside the app's process
    case webView
}
