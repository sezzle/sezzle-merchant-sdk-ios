# Sezzle Merchant SDK for iOS

Let your customers pay with Sezzle directly in your iOS app. The SDK handles checkout session creation, secure browser presentation, and promotional messaging — all with a single public key.

## Requirements

- iOS 14.0+
- Xcode 16+

## Installation

### Swift Package Manager

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter the repository URL: `https://github.com/sezzle/sezzle-merchant-sdk-ios`
3. Select **Up to Next Major Version** and choose the latest release
4. Add **SezzleMerchantSDK** to your target

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'SezzleMerchantSDK'
```

Then run `pod install`.

## Get Your API Keys

1. Log into the [Sezzle Merchant Dashboard](https://dashboard.sezzle.com)
2. Go to **Settings > API Keys**
3. Copy your **public key** (starts with `sz_pub_...`)

> Sandbox and production keys are separate. Use your sandbox key during development and testing.

## Step 1: Configure the SDK

Call `configure` once at app startup, before any other SDK calls.

**UIKit (AppDelegate):**

```swift
import SezzleMerchantSDK

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    SezzleSDK.shared.configure(
        publicKey: "sz_pub_...",  // your public key from the dashboard
        environment: .sandbox     // use .production for live transactions
    )
    return true
}
```

**SwiftUI (App):**

```swift
import SezzleMerchantSDK

@main
struct MyApp: App {
    init() {
        SezzleSDK.shared.configure(
            publicKey: "sz_pub_...",
            environment: .sandbox
        )
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

## Step 2: Add Promotional Messaging

The widget automatically shows the right message based on the product price:

- **Under $50:** "or 4 payments of $X.XX with Sezzle"
- **$50 and over:** "or 5 payments of $X.XX with Sezzle"
- **Long-term eligible:** "or monthly payments as low as $X.XX with Sezzle"
- **Below $35 or above $2,500:** hidden

```swift
import SezzleMerchantSDK

// Basic — uses default config (PI4 under $50, PI5 at $50+)
let promoView = SezzlePromotionalView(
    amountInCents: 4999,           // $49.99 → "or 4 payments of $12.49"
    presentingFrom: self
)
stackView.addArrangedSubview(promoView)
```

Update when the price changes:

```swift
promoView.update(amountInCents: newTotalInCents)
```

Tapping the view opens an info modal showing the payment schedule.

### Widget Configuration

Customize thresholds and enable long-term payments:

```swift
// Enable long-term monthly payments for orders over $250
let config = SezzleWidgetConfig(
    minPriceInCents: 3500,         // $35 minimum (default)
    maxPriceInCents: 250_000,      // $2,500 PI4/PI5 max (default)
    enablePayIn5: true,            // 5-pay for $50+ (default: true)
    pi5MinPriceInCents: 5000,      // $50 PI5 threshold (default)
    longTermConfig: SezzleLongTermConfig(
        minPriceInCents: 25_000    // LT kicks in at $250+
    )
)

let promoView = SezzlePromotionalView(
    amountInCents: 79900,          // $799 → "or monthly payments as low as $36.13"
    widgetConfig: config,
    presentingFrom: self
)
```

### Styling

`SezzlePromotionalView` automatically detects dark mode and selects the correct logo variant. You can also override the style manually:

```swift
// Explicit dark theme (light text + white logo for dark backgrounds)
let promoView = SezzlePromotionalView(
    amountInCents: 4999,
    style: .dark,
    presentingFrom: self
)
```

### Custom Promo UI

For full control over the promotional message:

```swift
SezzlePromoDataHandler.getMessage(amountInCents: 4999, widgetConfig: config) { attributedString in
    myCustomLabel.attributedText = attributedString
}
```

### Manual Info Modal

Present the info modal programmatically:

```swift
SezzleInfoModal.present(amountInCents: 4999, from: self)
```

## Step 3: Start Checkout

Build the order and start the checkout flow:

```swift
let checkout = SezzleCheckout(
    customer: SezzleCustomer(
        email: "jane@example.com",
        firstName: "Jane",
        lastName: "Doe"
    ),
    order: SezzleOrder(
        referenceId: "order-123",
        description: "Order from MyApp",
        amount: SezzleAmount(amountInCents: 4999, currency: "USD"),
        items: [
            SezzleItem(
                name: "Premium Widget",
                sku: "widget-001",
                quantity: 1,
                price: SezzleAmount(amountInCents: 4999, currency: "USD")
            )
        ]
    )
)

SezzleSDK.shared.startCheckout(checkout, from: self, delegate: self)
```

This opens the Sezzle checkout in a secure system browser. No WebView, no Info.plist changes — it just works.

### WebView Mode

To keep the user inside your app during checkout, use `.webView` mode:

```swift
SezzleSDK.shared.startCheckout(checkout, from: self, delegate: self, mode: .webView)
```

The checkout opens in an embedded WKWebView with a clean header. Trade-off: no cookie sharing with Safari (user logs in every time).

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `customer.email` | Yes | Customer's email address |
| `customer.firstName` | No | Customer's first name |
| `customer.lastName` | No | Customer's last name |
| `customer.phone` | No | Customer's phone number |
| `order.referenceId` | Yes | Your internal order ID |
| `order.description` | No | Order description (defaults to "Mobile SDK Order") |
| `order.amount.amountInCents` | Yes | Total amount in cents (e.g., 4999 = $49.99) |
| `order.amount.currency` | Yes | ISO 4217 currency code ("USD", "CAD") |
| `order.intent` | No | `.auth` (default) or `.capture` |
| `order.items` | No | Line items in the order |

## Step 4: Handle the Result

Implement `SezzleCheckoutDelegate` to receive callbacks:

```swift
extension MyViewController: SezzleCheckoutDelegate {
    func checkoutDidComplete(orderUUID: String) {
        // Checkout succeeded!
        // Send orderUUID to your backend to capture the payment.
        print("Order UUID: \(orderUUID)")
    }

    func checkoutDidCancel() {
        // User cancelled the checkout from within the Sezzle checkout page.
    }

    func checkoutDidFail(error: SezzleError) {
        // Something went wrong.
        print("Error: \(error.localizedDescription)")
    }
}
```

All delegate methods are called on the main thread.

## Step 5: Complete the Order (Server-Side)

After `checkoutDidComplete` returns the order UUID, your app sends it to your backend. Your backend then calls the Sezzle API to capture the payment:

```
POST https://gateway.sezzle.com/v2/order/{orderUUID}/capture
Authorization: Bearer {your_bearer_token}
Content-Type: application/json

{
  "capture_amount": {
    "amount_in_cents": 4999,
    "currency": "USD"
  }
}
```

> Capture, refund, release, and order status are always server-to-server calls using your private key. The SDK never handles these operations.

See the [Sezzle API documentation](https://docs.sezzle.com) for full details on server-side operations.

## Error Handling

| Error | When it happens | What to do |
|-------|----------------|------------|
| `.notConfigured` | `startCheckout` called before `configure` | Call `SezzleSDK.shared.configure(...)` at app startup |
| `.networkError(Error)` | No internet, timeout, DNS failure | Show a retry option to the user |
| `.apiError(statusCode, message)` | Sezzle API returned an error (e.g., invalid key, bad request) | Check the status code and message for details |
| `.browserDismissed` | User swiped away the checkout browser | Return to the previous screen |
| `.invalidResponse` | API response couldn't be parsed | Retry, or contact support if persistent |

## Example App

The repository includes a working example app that demonstrates the full integration.

To run it:

1. Open `Example/SezzleCheckoutExample.xcodeproj` in Xcode
2. Copy `Secrets.swift.template` to `Secrets.swift` and add your sandbox public key:
   ```swift
   enum Secrets {
       static let sezzlePublicKey = "sz_pub_your_key_here"
   }
   ```
   This file is gitignored — your key stays out of version control.
3. Select a simulator and hit Run

The example app shows:
- **Product screen** with `SezzlePromotionalView` and a "Pay with Sezzle" button
- **Checkout flow** opening the Sezzle browser and handling the result
- **Result screen** showing the order UUID on success, or the error on failure

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Checkout immediately fails with 401 | Wrong environment — sandbox key with `.production` or vice versa | Match the environment to your key type |
| "Order amount too low" error | Order total is below $35 | Ensure `amountInCents` is at least 3500 |
| Browser opens and closes instantly | Invalid or expired public key | Verify your key in the Merchant Dashboard |
| Promotional view doesn't appear | Amount below $35 or above $2,500 | Check the amount is within the eligible range |
| `.notConfigured` error | `configure` wasn't called before `startCheckout` | Move `configure` to `AppDelegate.didFinishLaunchingWithOptions` |

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

MIT License. See [LICENSE](LICENSE) for details.
