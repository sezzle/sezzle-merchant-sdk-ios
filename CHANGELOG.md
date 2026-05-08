# Changelog

All notable changes to the Sezzle Merchant SDK for iOS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
