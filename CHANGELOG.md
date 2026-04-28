# Changelog

All notable changes to the Sezzle Merchant SDK for iOS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
