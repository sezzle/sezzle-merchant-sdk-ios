# Sezzle Checkout Example App

A working iOS app that demonstrates how to integrate the Sezzle Merchant SDK.

## Quick Start

1. **Get your sandbox key**: Log into the [Sezzle Merchant Dashboard](https://dashboard.sezzle.com) > Settings > API Keys > copy your public key
2. **Add your key**: Open `AppDelegate.swift` and replace `"YOUR_SANDBOX_PUBLIC_KEY"` with your key
3. **Run**: Open `SezzleCheckoutExample.xcodeproj`, select a simulator, and hit Run

## What It Demonstrates

### Product Screen
- `SezzlePromotionalView` embedded below the product price
- Shows "or 4 interest-free payments of $X.XX with Sezzle"
- Tap the promo message to see the info modal with payment schedule
- "Pay with Sezzle" button starts the checkout flow

### Result Screen
- **Success**: Shows the order UUID — send this to your backend to capture the payment
- **Cancelled**: User cancelled from within the Sezzle checkout page
- **Error**: Shows the error description with a back button

## Test Scenarios

| Scenario | How to test | Expected result |
|----------|-------------|-----------------|
| Successful checkout | Tap "Pay with Sezzle", complete checkout in browser | Result screen shows order UUID |
| Cancel in checkout | Tap "Pay with Sezzle", tap "Return to Store" in browser | Result screen shows "cancelled" |
| Dismiss browser | Tap "Pay with Sezzle", swipe down the browser | Result screen shows "browser dismissed" |
| Promo view tap | Tap the "or 4 interest-free payments..." text | Info modal opens with payment schedule |
