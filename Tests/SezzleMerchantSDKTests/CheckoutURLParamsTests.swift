import XCTest
@testable import SezzleMerchantSDK

final class CheckoutURLParamsTests: XCTestCase {

    private func queryItems(_ url: URL) -> [String: String] {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(items.compactMap { item in
            item.value.map { (item.name, $0) }
        }, uniquingKeysWith: { first, _ in first })
    }

    func testAppendsIsMerchantSDK() throws {
        let url = try XCTUnwrap(
            CheckoutHandler.appendSDKParams(
                to: "https://checkout.sezzle.com/?id=abc",
                theme: "light"
            )
        )
        XCTAssertEqual(queryItems(url)["isNativeSDK"], "true")
    }

    /// `isNativeSDK` alone suppresses checkout's navigation bar, so `isWebView` is redundant
    /// for chrome. Sending it is actively harmful: checkout reads it as the Sezzle consumer
    /// app and routes TILA through a React Native postMessage no merchant app receives.
    func testDoesNotAppendIsWebView() throws {
        let url = try XCTUnwrap(
            CheckoutHandler.appendSDKParams(
                to: "https://checkout.sezzle.com/?id=abc",
                theme: "light"
            )
        )
        XCTAssertNil(queryItems(url)["isWebView"])
    }

    func testExistingIsNativeSDKIsNotDuplicated() throws {
        let url = try XCTUnwrap(
            CheckoutHandler.appendSDKParams(
                to: "https://checkout.sezzle.com/?id=abc&isNativeSDK=true",
                theme: "light"
            )
        )
        let flags = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.filter { $0.name == "isNativeSDK" } ?? []
        XCTAssertEqual(flags.count, 1)
    }

    func testPreservesExistingQueryParams() throws {
        let url = try XCTUnwrap(
            CheckoutHandler.appendSDKParams(
                to: "https://checkout.sezzle.com/?id=abc&locale=en-US",
                theme: "light"
            )
        )
        let items = queryItems(url)
        XCTAssertEqual(items["id"], "abc")
        XCTAssertEqual(items["locale"], "en-US")
    }

    func testAppendsDarkTheme() throws {
        let url = try XCTUnwrap(
            CheckoutHandler.appendSDKParams(
                to: "https://checkout.sezzle.com/?id=abc",
                theme: "dark"
            )
        )
        XCTAssertEqual(queryItems(url)["theme"], "dark")
    }

    func testAppendsLightTheme() throws {
        let url = try XCTUnwrap(
            CheckoutHandler.appendSDKParams(
                to: "https://checkout.sezzle.com/?id=abc",
                theme: "light"
            )
        )
        XCTAssertEqual(queryItems(url)["theme"], "light")
    }

    /// A theme already on the checkout URL is the merchant's explicit choice — the
    /// auto-detected app appearance must not clobber it.
    func testExistingThemeIsNotOverridden() throws {
        let url = try XCTUnwrap(
            CheckoutHandler.appendSDKParams(
                to: "https://checkout.sezzle.com/?id=abc&theme=dark",
                theme: "light"
            )
        )
        let themes = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.filter { $0.name == "theme" } ?? []
        XCTAssertEqual(themes.count, 1)
        XCTAssertEqual(themes.first?.value, "dark")
    }

    func testURLWithNoExistingQueryString() throws {
        let url = try XCTUnwrap(
            CheckoutHandler.appendSDKParams(
                to: "https://checkout.sezzle.com/checkout",
                theme: "dark"
            )
        )
        let items = queryItems(url)
        XCTAssertEqual(items["isNativeSDK"], "true")
        XCTAssertEqual(items["theme"], "dark")
    }

    /// Unparseable input hits the `guard` and yields nil, which callers surface as
    /// `.invalidResponse` rather than opening a broken checkout.
    func testUnparseableURLReturnsNil() {
        XCTAssertNil(CheckoutHandler.appendSDKParams(to: "http://[", theme: "light"))
        XCTAssertNil(CheckoutHandler.appendSDKParams(to: "https://exa mple.com", theme: "light"))
    }
}
