import Foundation

/// The Sezzle environment to use for API requests.
///
/// Use `.sandbox` during development and testing, and `.production` for live transactions.
///
/// ```swift
/// SezzleSDK.shared.configure(publicKey: "sz_pub_...", environment: .sandbox)
/// ```
public enum SezzleEnvironment: Sendable {
    /// Sandbox environment for development and testing.
    case sandbox
    /// Production environment for live transactions.
    case production

    var gatewayURL: URL {
        switch self {
        case .sandbox:
            URL(string: "https://sandbox.gateway.sezzle.com")!
        case .production:
            URL(string: "https://gateway.sezzle.com")!
        }
    }
}
