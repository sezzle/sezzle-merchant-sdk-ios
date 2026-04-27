import Foundation

/// Finds the resource bundle for the SDK.
/// Works with both SPM (Bundle.module) and CocoaPods (resource bundle in framework bundle).
enum SezzleBundle {
    nonisolated(unsafe) static let resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let frameworkBundle = Bundle(for: SezzlePromotionalView.self)
        // CocoaPods resource_bundles creates a .bundle inside the framework
        if let podBundleURL = frameworkBundle.url(forResource: "SezzleMerchantSDK", withExtension: "bundle"),
           let podBundle = Bundle(url: podBundleURL) {
            return podBundle
        }
        return frameworkBundle
        #endif
    }()
}
