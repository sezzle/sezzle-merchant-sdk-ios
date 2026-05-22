import Foundation
import WebKit

/// Clears Sezzle-domain cookies and Web storage from `WKWebsiteDataStore.default()`.
///
/// Used by `SezzleSDK.clearWebViewData(completion:)`. Merchants should not call this
/// directly — the public API is `SezzleSDK.shared.clearWebViewData(...)`.
///
/// Why this exists: `WKWebsiteDataStore.default()` is the single app-wide persistent store
/// inherited by every WebView with the default `WKWebViewConfiguration`. Cookies set during
/// one user's Sezzle checkout (auth tokens, session identifiers) persist across users on the
/// same device. Without an explicit clear, the next user's first BNPL attempt can resume the
/// previous user's Sezzle session and surface their state to the wrong customer.
///
/// The clear is **scoped to Sezzle's own domains** — the merchant app's other cookies and
/// Web storage are not touched. `removeData(ofTypes:modifiedSince:)` would wipe the whole
/// store and is intentionally avoided.
@MainActor
enum SezzleCookieClearer {

    /// Display-name suffixes of `WKWebsiteDataRecord`s we want to delete. The records' display
    /// name is the eTLD+1 domain — both `sezzle.com` (covers prod apex + all subdomains)
    /// and any sandbox-specific suffix end with one of these.
    private static let sezzleSuffixes: [String] = [
        "sezzle.com",
    ]

    static func clear(completion: (@MainActor () -> Void)? = nil) {
        let store = WKWebsiteDataStore.default()
        let allTypes = WKWebsiteDataStore.allWebsiteDataTypes()

        store.fetchDataRecords(ofTypes: allTypes) { records in
            let sezzleRecords = records.filter { record in
                let name = record.displayName.lowercased()
                return sezzleSuffixes.contains { name == $0 || name.hasSuffix(".\($0)") }
            }

            Task { @MainActor in
                guard !sezzleRecords.isEmpty else {
                    completion?()
                    return
                }
                store.removeData(ofTypes: allTypes, for: sezzleRecords) {
                    Task { @MainActor in completion?() }
                }
            }
        }
    }
}
