import Foundation

/// Finds the resource bundle for the SDK.
/// SPM uses Bundle.module (auto-generated). CocoaPods uses resource_bundles.
enum SezzleBundle {
    nonisolated(unsafe) static let resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        // CocoaPods: resource_bundles creates a .bundle inside the framework
        let frameworkBundle = Bundle(for: SezzlePromotionalView.self)
        if let podBundleURL = frameworkBundle.url(forResource: "SezzleMerchantSDK", withExtension: "bundle"),
           let podBundle = Bundle(url: podBundleURL) {
            return podBundle
        }
        return frameworkBundle
        #endif
    }()
}
