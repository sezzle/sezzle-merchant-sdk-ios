import Foundation
import WebKit

/// Clears Sezzle's auth session: invalidates the server-side refresh token via
/// `POST /v4/users/logout`, then wipes Sezzle-domain cookies and Web storage
/// from `WKWebsiteDataStore.default()`.
///
/// Used by `SezzleSDK.clearWebViewData(completion:)`. Merchants should not call this
/// directly — the public API is `SezzleSDK.shared.clearWebViewData(...)`.
///
/// Why the server call: `WKWebsiteDataStore.default()` is the single app-wide persistent
/// store inherited by every WebView with the default `WKWebViewConfiguration`. Cookies set
/// during one user's Sezzle checkout (auth tokens, session identifiers) persist across users
/// on the same device. Wiping them locally is necessary but not sufficient — Sezzle's backend
/// also keeps a refresh-token-bound session that can re-recognize the device on the next
/// checkout. Calling `/v4/users/logout` with the WebView's cookies makes the backend forget
/// that binding so the next user starts truly fresh.
@MainActor
enum SezzleCookieClearer {

    /// Display-name suffixes of `WKWebsiteDataRecord`s we want to delete. The records' display
    /// name is the eTLD+1 domain — both `sezzle.com` (covers prod apex + all subdomains)
    /// and any sandbox-specific suffix end with one of these.
    private static let sezzleSuffixes: [String] = [
        "sezzle.com",
    ]

    /// Short timeout so a slow or unreachable logout endpoint never blocks the merchant's
    /// logout flow. The server-side invalidation is best-effort; the local data wipe always runs.
    private static let logoutTimeout: TimeInterval = 5.0

    static func clear(environment: SezzleEnvironment?, completion: (@MainActor () -> Void)? = nil) {
        Task { @MainActor in
            await invalidateServerSession(environment: environment ?? .production)
            removeLocalData(completion: completion)
        }
    }

    /// Reads all `*.sezzle.com` cookies from the WebView and POSTs them to `/v4/users/logout`.
    /// The SDK does not pick a subset — the backend decides which cookies are meaningful for
    /// the logout. Errors are swallowed by design.
    private static func invalidateServerSession(environment: SezzleEnvironment) async {
        let store = WKWebsiteDataStore.default()
        let cookies = await withCheckedContinuation { (cont: CheckedContinuation<[HTTPCookie], Never>) in
            store.httpCookieStore.getAllCookies { cont.resume(returning: $0) }
        }

        let sezzleCookies = cookies.filter { cookie in
            let domain = cookie.domain.lowercased()
            return sezzleSuffixes.contains { domain == $0 || domain.hasSuffix(".\($0)") }
        }
        guard !sezzleCookies.isEmpty else { return }

        let cookieHeader = sezzleCookies
            .map { "\($0.name)=\($0.value)" }
            .joined(separator: "; ")

        var request = URLRequest(url: environment.apiURL.appendingPathComponent("/v4/users/logout"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        // We attach cookies by header so they come from WKHTTPCookieStore, not HTTPCookieStorage.shared.
        request.httpShouldHandleCookies = false
        request.httpBody = Data("{}".utf8)
        request.timeoutInterval = logoutTimeout

        _ = try? await URLSession.shared.data(for: request)
    }

    /// The clear is **scoped to Sezzle's own domains** — the merchant app's other cookies and
    /// Web storage are not touched. `removeData(ofTypes:modifiedSince:)` would wipe the whole
    /// store and is intentionally avoided.
    private static func removeLocalData(completion: (@MainActor () -> Void)? = nil) {
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
