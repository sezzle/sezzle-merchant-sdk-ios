import XCTest
import WebKit
@testable import SezzleMerchantSDK

/// Verifies `SezzleSDK.clearWebViewData(completion:)` — the public API for merchants to
/// purge Sezzle's cookies and Web storage from `WKWebsiteDataStore.default()` (typically
/// called on user logout, to prevent cross-user session leak in `.webView` mode).
///
/// The SDK does not clear automatically; merchants are responsible for calling this when their
/// user signs out. These tests verify the API exists, can be called safely with no Sezzle data
/// present, and that the completion handler fires on the main queue.
@MainActor
final class SezzleClearWebViewDataTests: XCTestCase {

    func testClearWebViewDataInvokesCompletionWhenNoSezzleData() {
        let expectation = expectation(description: "completion called")
        SezzleSDK.shared.clearWebViewData {
            // Completion must fire on the main queue per the API contract.
            dispatchPrecondition(condition: .onQueue(.main))
            expectation.fulfill()
        }
        // CI sometimes takes 5+ seconds for the first WKWebsiteDataStore.fetchDataRecords call
        // on a freshly-booted simulator (cold-start init). Generous timeout.
        wait(for: [expectation], timeout: 30.0)
    }

    func testClearWebViewDataIsSafeWithoutCompletion() {
        // Fire-and-forget — should not crash, should not block.
        SezzleSDK.shared.clearWebViewData()
        SezzleSDK.shared.clearWebViewData(completion: nil)
    }

    func testClearWebViewDataIsIdempotent() {
        let expectation1 = expectation(description: "first call done")
        let expectation2 = expectation(description: "second call done")
        SezzleSDK.shared.clearWebViewData {
            expectation1.fulfill()
            SezzleSDK.shared.clearWebViewData {
                expectation2.fulfill()
            }
        }
        wait(for: [expectation1, expectation2], timeout: 60.0)
    }
}
