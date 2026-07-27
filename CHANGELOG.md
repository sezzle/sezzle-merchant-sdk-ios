# Changelog

All notable changes to the Sezzle Merchant SDK for iOS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-07-27

### Added
- **`isMerchantSDK=true` on the checkout URL, sent alongside the existing `isWebView=true`.** The two flags mean different things and both are required. `isWebView` tells checkout it is embedded rather than standalone, which is what suppresses checkout's own navigation bar — this SDK draws its own close-button header, so without the flag two bars stack. `isMerchantSDK` then narrows that to *this* SDK rather than the Sezzle consumer app: checkout keeps the authentication back button available and suppresses the third-party OAuth sign-in providers, which do not complete reliably inside an embedded WebView.

- **`theme` on the checkout URL, auto-detected from the host app's appearance.** Resolved from the presenting view controller's `traitCollection.userInterfaceStyle` and sent as `theme=dark` or `theme=light`. Checkout does not reliably observe the host app's appearance through `prefers-color-scheme` inside a WebView, so the SDK passes it explicitly. A `theme` already present on a merchant-supplied checkout URL is respected and never overridden.

  The SDK always sends a concrete `dark` or `light`, never `system` — so checkout follows the *host app's* appearance rather than the device-level setting. For an app that pins itself to light mode on a device set to dark, checkout stays light and matches the surrounding app.

  **Note:** dark rendering is gated on the checkout side and is not yet active for SDK checkouts. Checkout only applies a dark palette when its dark-theme rollout flag resolves for the shopper, and that flag is not evaluated before the shopper authenticates — which in an SDK checkout is after the page has already rendered. The SDK sends the parameter correctly today; checkout will honour it once that gating changes. Until then expect a light checkout regardless of the host app's appearance.

- **`SezzleUserAgentMode` on `SezzleOrder`, defaulting to `.redirect`.** Sent as `order.checkout_mode` on `POST /v2/session` and recorded on the checkout as `sezzle_user_agent_mode`. Checkout previously had no mode recorded for SDK-created sessions and emitted a diagnostic event for the omission; `.redirect` is the accurate description of how this SDK operates, since completion is detected from the redirect to your complete or cancel URL.

  Override it via `SezzleOrder(..., userAgentMode:)` if you have a reason to. Note this only applies to sessions the SDK creates — on the server-driven `startCheckout(checkoutURL:)` path the session is created by your backend, so set `order.checkout_mode` there instead.

### Compatibility
- **Additive API change.** `SezzleOrder` gains one parameter with a default value, so existing initializer calls compile unchanged.
- No new permissions and no new dependencies.
- Merchants who construct their own checkout URL and pass it to `startCheckout(checkoutURL:)` will now see `isMerchantSDK` and `theme` appended to it, in addition to the `isWebView` this SDK already appended. Any `isWebView` or `theme` you set yourself is preserved.
- No change to checkout's navigation bar, which `isWebView` continues to suppress.

### Notes
- A handful of checkout behaviours still key off `isWebView` alone and assume the Sezzle consumer app's React Native bridge — notably the consumer-lending disclosure hand-off for purchase-request and gift-card checkouts, which posts to a bridge a merchant app does not implement. Those paths need an `isMerchantSDK` exclusion on the checkout side; that work is tracked separately and is not addressed by this release.

## [1.2.4] - 2026-06-03

### Changed
- **`clearWebViewData()` now forwards every `*.sezzle.com` cookie to `/v4/users/logout`**, not just `access_token` + `refresh_token`. The SDK takes no opinion about which cookies are auth-bearing — that's the backend's call. In practice this means cookies like `trk_id`, `__szl_email`, `szl_wpe_sid`, `_szlcpref`, `checkoutUuid`, etc. are now included in the logout request whenever they're present in the WebView's cookie jar.

  Rationale: the 1.2.3 release forwarded only `access_token` + `refresh_token`, which was enough for the refresh-token revocation step but missed cookies that other server-side cleanup paths key on. Sending everything lets Sezzle's backend extend the logout's effect over time without requiring a new SDK release each time.

### Compatibility
- No public API changes. No new permissions. No new dependencies.
- Behavior change is contained to the body of the `POST /v4/users/logout` request the SDK makes from `clearWebViewData()` — no impact on `startCheckout`, `SezzlePromotionalView`, or any other public surface.
- No-op when no `*.sezzle.com` cookies are present (safe to call before any checkout has ever run).

## [1.2.3] - 2026-05-29

### Fixed
- **`clearWebViewData()` now also invalidates the server-side Sezzle session.** On a real device, even after the WebView's cookies and Web storage are fully cleared (which 1.2.2's implementation does correctly), Sezzle's backend was still able to recognize the device on the next checkout and pre-bind the new session to the prior user's account — so merchant apps with multi-user flows saw the next user land on the place-order screen authenticated as the previous user.

  As of 1.2.3, `clearWebViewData()` now performs **two** steps in order:

  1. Reads the WebView's Sezzle `access_token` + `refresh_token` cookies (if present) and POSTs them to `/v4/users/logout` so the backend invalidates the refresh token and forgets the device→user binding. Best-effort — 5 second timeout, errors are swallowed so a slow network never blocks the merchant's logout flow.
  2. Removes Sezzle-domain cookies and Web storage from `WKWebsiteDataStore.default()` (the existing 1.2.2 behavior, unchanged).

  Merchants don't need to change anything — same public API, same call site on user logout. The call sequence above runs automatically.

  ```swift
  // Same call as before — now closes the loop server-side as well.
  SezzleSDK.shared.clearWebViewData {
      // Safe to start a new Sezzle checkout for a different user from here.
  }
  ```

### Compatibility
- No public API changes. No new permissions. No new dependencies.
- The logout call uses `URLSession.shared` against `api.sezzle.com` (or `sandbox.api.sezzle.com` when configured for `.sandbox`). If the SDK was never `configure(...)`d (server-driven flow), the call defaults to production.
- No-op when no Sezzle auth cookies are present (safe to call repeatedly, safe to call when no Sezzle checkout has ever run).

## [1.2.2] - 2026-05-22

### Added
- **`SezzleSDK.shared.clearWebViewData(completion:)`** — new public API for merchants to clear Sezzle's cookies and Web storage from `WKWebsiteDataStore.default()`. **Call this on user logout** (or account switch) so the next Sezzle checkout starts with a fresh session.

  ```swift
  // In your merchant app's logout flow:
  func onUserLogout() {
      // ...clear your own session state...
      SezzleSDK.shared.clearWebViewData()
  }

  // Or with a completion handler if you need to know when it's done:
  SezzleSDK.shared.clearWebViewData {
      // safe to start a new Sezzle checkout as a different user now
  }
  ```

  Why this is needed: iOS's `WKWebsiteDataStore.default()` is a single app-wide persistent store. Cookies set during one user's Sezzle checkout (auth tokens, session identifiers) persist across users on the same device — without this call, the next user's first BNPL attempt can resume the previous user's Sezzle session and surface their state (e.g. credit-limit decline) to the wrong customer.

  The clear is **scoped to Sezzle's own domains** (`sezzle.com` and all subdomains) — your other cookies and Web storage are not touched. Safe to call repeatedly; safe to call when no Sezzle checkout has ever run in this process. The operation is asynchronous; the optional completion handler fires on the main queue.

  Affects `.webView` mode only. `.systemBrowser` mode (`ASWebAuthenticationSession` sharing cookies with Chrome / Safari) is outside the SDK's reach.

### Compatibility
- **No automatic clearing.** Merchants who don't call `clearWebViewData()` will still see the cross-user cookie leak in `.webView` mode. This is intentional — the SDK does not assume when a logout has happened; you do. Returning Sezzle users keep their persistent login between checkouts under the same merchant-app user, which is preferable when only one person uses the device.
- Version jumps from 1.2.1 → 1.2.2 sequentially. No public API removals. No new permissions. No new dependencies. Existing integrations recompile and link without modification — only merchants implementing multi-user flows need to wire up the new call.

## [1.2.1] - 2026-05-08

### Fixed
- **WebView checkout: external links (Terms, Privacy, etc.) now open in Safari.** `SezzleCheckoutWebViewController` now conforms to `WKUIDelegate` and routes `target="_blank"` / `window.open()` navigations to `UIApplication.shared.open()`. Previously these were silently blocked by `WKWebView`'s default no-popup policy.
- **Reject overlapping `startCheckout` calls.** Rapid double-taps used to fire a second `startCheckout` while the first was still presenting, which on `.systemBrowser` mode caused `ASWebAuthenticationSession` to fail with `WebAuthenticationSession error 3` (`presentationContextInvalid`) and report a bogus `checkoutDidFail(.networkError(...))` to the merchant. SezzleSDK now tracks an in-progress flag and silently ignores overlapping calls until the first delivers its terminal callback.
- **Internal:** `CheckoutHandler.delegate` is now strongly held (was `weak`). The new `ProgressTrackingDelegate` wrapper used by the in-progress guard is created locally in `SezzleSDK.startCheckout` — under the previous `weak` reference it was deallocated before any callback could fire, leaving the in-progress gate stuck and blocking all subsequent checkouts. `cleanup()` releases the reference after `deliverResult`, so no retain cycles are introduced.

## [1.2.0] - 2026-05-06

### Added
- Server-driven checkout entrypoint — `SezzleSDK.shared.startCheckout(checkoutURL:completeURL:cancelURL:from:delegate:mode:)` for merchants whose backend creates the session via `POST /v2/session` directly. No public key on-device, no `configure(publicKey:)` required. Merchants supply their own callback URLs (any scheme) and the SDK intercepts navigation to them.
- `SezzleCheckoutResult` — unified result struct exposing `orderUUID` (SDK-creates-session flow) or `callbackURL` (server-driven flow). The full callback URL is delivered so merchants can encode their own state in query params (e.g. `yourapp-sezzle://done?orderRef=12345`) and recover it on completion.

### Changed
- `SezzleCheckoutDelegate.checkoutDidComplete` now receives a `SezzleCheckoutResult` instead of a bare `orderUUID` string, unifying both flows behind a single delegate method.
- `CheckoutHandler` URL match logic is now dynamic — compares scheme + host + path against the merchant's callback URLs (case-insensitive on scheme/host). Existing flow continues to use the hardcoded `sezzle-sdk://checkout/(confirmed|cancelled)` URLs.
- `WKURLSchemeHandler` registration is now per-checkout (registered for the merchant's callback scheme) and skipped for `http`/`https`.
- `SezzleEventLogger` no-ops gracefully on the server-driven flow (no public key = no events).

## [1.1.0] - 2026-04-30

### Added
- Full POST /v2/session API support — all fields from the Sezzle API are now available:
  - `SezzleAddress` — billing and shipping addresses on `SezzleCustomer`
  - `SezzleDiscount` — order discount line items
  - `SezzleLocale` — checkout locale (`enUS`, `enCA`, `frCA`)
  - `SezzleFinancingOption` — restrict to specific financing plans
  - `SezzleItem` gains `brand`, `imageUrl`, `productUrl`, `globalTradeItemNumber`, `manufacturerPartNumber`, `categoryPath`
  - `SezzleCustomer` gains `dob`, `billingAddress`, `shippingAddress`, `tokenize`, `recurring`, `recurringMetadata`
  - `SezzleOrder` gains `discounts`, `taxAmount`, `shippingAmount`, `metadata`, `requiresShippingInfo`, `locale`, `checkoutFinancingOptions`
- SDK event logging — fire-and-forget telemetry to Sezzle's event pipeline (`/sdk-event-logging`)
  - Events: `popup_created`, `loaded`, `success`, `cancel`, `failure`
  - Includes SDK version, platform, device model, OS version in user agent
  - Enables checkout funnel analytics and SDK attribution
- SDK metadata in order — `_sdk_platform`, `_sdk_version`, `_device_model`, `_os_version` automatically included in `order.metadata` for attribution tracking

### Changed
- `isWebView=true` now appended to checkout URL for both system browser and WebView modes (moved from WebView controller to CheckoutHandler)
- SDK version bumped to 1.1.0

## [1.0.5] - 2026-04-28

### Added
- Dark mode logo variant — white wordmark (`Sezzle_Logo_FullColor_WhiteWM`) for dark backgrounds
- Auto-detection of dark mode in `SezzlePromotionalView` — selects correct logo variant automatically
- `SezzleLogoVariant` enum for explicit light/dark logo control
- `traitCollectionDidChange` support — promo view re-renders when appearance changes
- Centralized brand colors: `scheduleAmount`, `scheduleDate`, `pieChartBg` in `SezzleBrand`

### Changed
- Info modal header now shows the official Sezzle logo image instead of "✦ sezzle" text
- High-quality logo PNGs (2394×599 @ 3x) converted from official CDN SVGs via cairosvg
- Pie chart background in dark mode uses semi-transparent white for better contrast on purple cards
- Schedule card amounts use white text in dark mode for readability

### Fixed
- Inline promo logo was always dark variant regardless of appearance mode
- Schedule card text was barely readable in dark mode (purple on purple)
- Removed non-functional WebView back button (Sezzle checkout SPA doesn't support browser history navigation)
- Removed "sezzle.com" title from WebView header — clean close-button-only design

## [1.0.2] - 2026-04-27

### Fixed
- Remove unnecessary `nonisolated(unsafe)` compiler warning on `BundleHelper.resourceBundle`
- Fix `WKNavigationDelegate` method signature warnings by adding `@MainActor @Sendable` to decision handler closures
- Clean build with zero warnings for both SPM and CocoaPods

## [1.0.1] - 2026-04-27

### Added
- `SezzleWidgetConfig` — configurable widget with PI4/PI5/long-term support matching sezzle-js source of truth
- PI4: "or 4 payments of $X" (default, under $50)
- PI5: "or 5 payments of $X" (enabled, $50+)
- Long-term: "or monthly payments as low as $X" (configurable threshold, APR amortization)
- Removed "interest-free" from all messaging (matches sezzle-js)
- `SezzleInfoModal` now shows PI4, PI5, or long-term modal based on price
- `SezzleCheckoutMode` — choose between `.systemBrowser` (default) or `.webView`
- WebView mode: loading spinner, white header with "sezzle.com", `isWebView=true` query param
- Example app shows all 4 widget variants: hidden, PI4, PI5, and long-term

### Fixed
- Guard against double delegate callbacks — delivers results exactly once per checkout
- WebView checkout redirect: `WKURLSchemeHandler` + KVO observer + error handler fallbacks
- SPM + CocoaPods resource compatibility via `BundleHelper`

## [1.0.0] - 2026-04-22

### Added

- `SezzleSDK` — configure with your public key and start checkouts
- `SezzleCheckoutDelegate` — receive checkout completion, cancellation, and error callbacks
- `SezzlePromotionalView` — drop-in installment messaging for product and cart pages
- `SezzleInfoModal` — educational modal explaining how Sezzle works with payment schedule
- `SezzlePromoDataHandler` — raw attributed string for custom promotional UI
- Sandbox and production environment support
- Example app demonstrating the full integration
