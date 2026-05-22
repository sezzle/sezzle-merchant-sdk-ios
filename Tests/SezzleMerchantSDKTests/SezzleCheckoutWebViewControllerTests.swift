import XCTest
import WebKit
@testable import SezzleMerchantSDK

/// Verifies the cookie-isolation fix for the WebView checkout flow.
///
/// Why: `WKWebViewConfiguration()` defaults to `WKWebsiteDataStore.default()` — a shared,
/// persistent, app-wide data store. Sezzle cookies set during one user's checkout would
/// then leak into the next user's session on the same device. The fix configures
/// `.nonPersistent()` so each checkout WebView has its own ephemeral in-memory data store.
/// Reported by Poshmark — User A's credit-limit decline showing for User B after a
/// logout/login.
@MainActor
final class SezzleCheckoutWebViewControllerTests: XCTestCase {

    private final class StubDelegate: SezzleCheckoutDelegate {
        func checkoutDidComplete(result: SezzleCheckoutResult) {}
        func checkoutDidCancel() {}
        func checkoutDidFail(error: SezzleError) {}
    }

    private func makeController() -> SezzleCheckoutWebViewController {
        let controller = SezzleCheckoutWebViewController(
            checkoutURL: URL(string: "https://sandbox.checkout.sezzle.com/?id=test")!,
            completeURL: URL(string: "sezzle-sdk://checkout/confirmed")!,
            cancelURL: URL(string: "sezzle-sdk://checkout/cancelled")!,
            delegate: StubDelegate()
        )
        // Force view hierarchy creation so `setupWebView()` runs.
        controller.loadViewIfNeeded()
        return controller
    }

    func testWebViewUsesNonPersistentDataStore() {
        let controller = makeController()
        XCTAssertFalse(
            controller.webView.configuration.websiteDataStore.isPersistent,
            "WebView checkout must use an ephemeral data store so Sezzle cookies don't leak across users on the same device. Configure WKWebViewConfiguration.websiteDataStore = .nonPersistent() in setupWebView()."
        )
    }

    func testWebViewDataStoreIsIsolatedFromDefault() {
        let controller = makeController()
        // Identity check — the controller's data store must NOT be the shared default.
        XCTAssertFalse(
            controller.webView.configuration.websiteDataStore === WKWebsiteDataStore.default(),
            "WebView is using WKWebsiteDataStore.default() — cookies will persist across checkouts and leak between users."
        )
    }

    func testTwoControllersGetIndependentDataStores() {
        // Each presented checkout instance should have its own ephemeral store, so cookies
        // set during one checkout don't reach a subsequent one even within the same process.
        let a = makeController()
        let b = makeController()
        XCTAssertFalse(
            a.webView.configuration.websiteDataStore === b.webView.configuration.websiteDataStore,
            "Two checkout controllers share the same data store — cookies from checkout #1 will be visible to checkout #2."
        )
    }
}
