import UIKit
import SezzleMerchantSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Add your sandbox public key from the Sezzle Merchant Dashboard.
    // Create Example/SezzleCheckoutExample/Secrets.swift with:
    //   enum Secrets { static let sezzlePublicKey = "sz_pub_your_key_here" }
    // This file is gitignored to keep keys out of version control.
    private let sezzlePublicKey = Secrets.sezzlePublicKey

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure the Sezzle SDK once at app startup.
        // Use .sandbox for testing, .production for live transactions.
        SezzleSDK.shared.configure(
            publicKey: sezzlePublicKey,
            environment: .sandbox
        )
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
