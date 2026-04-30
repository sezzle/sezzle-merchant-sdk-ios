import Foundation
import UIKit

/// Fire-and-forget event logging to `{gateway}/sdk-event-logging`.
struct SezzleEventLogger: Sendable {
    let publicKey: String
    let environment: SezzleEnvironment

    enum Event: String, Sendable {
        case popupCreated = "popup_created"
        case renderPopup = "render_popup"
        case loaded = "loaded"
        case success = "success"
        case cancel = "cancel"
        case failure = "failure"
        case logError = "log_error"
    }

    @MainActor
    func log(
        event: Event,
        sessionUUID: String = "",
        orderUUID: String = "",
        checkoutUUID: String = "",
        mode: String = "",
        message: String = "",
        payloadSupplied: Bool = false
    ) {
        let userAgent = "SezzleMerchantSDK-iOS/\(HTTPClient.sdkVersion) (\(UIDevice.current.model); iOS \(UIDevice.current.systemVersion))"

        let body: [String: Any] = [
            "version": HTTPClient.sdkVersion,
            "event": event.rawValue,
            "user_agent": userAgent,
            "session_uuid": sessionUUID,
            "order_uuid": orderUUID,
            "payload_supplied": payloadSupplied,
            "checkout_uuid": checkoutUUID,
            "mode": mode,
            "message": message,
        ]

        let url = environment.gatewayURL.appendingPathComponent("/sdk-event-logging")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoded = Data(publicKey.utf8).base64EncodedString()
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // Fire-and-forget — don't await, don't handle errors
        Task.detached(priority: .utility) {
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
