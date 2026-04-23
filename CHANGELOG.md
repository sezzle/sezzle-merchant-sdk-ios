# Changelog

All notable changes to the Sezzle Merchant SDK for iOS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Guard against double delegate callbacks — `CheckoutHandler` now delivers results exactly once per checkout, preventing stale state from previous checkouts leaking into subsequent ones
- Delegate and internal state cleaned up immediately after result delivery

## [1.0.0] - 2026-04-22

### Added

- `SezzleSDK` — configure with your public key and start checkouts
- `SezzleCheckoutDelegate` — receive checkout completion, cancellation, and error callbacks
- `SezzlePromotionalView` — drop-in installment messaging for product and cart pages
- `SezzleInfoModal` — educational modal explaining how Sezzle works with payment schedule
- `SezzlePromoDataHandler` — raw attributed string for custom promotional UI
- Sandbox and production environment support
- Example app demonstrating the full integration
