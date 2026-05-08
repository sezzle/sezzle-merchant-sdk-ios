import Foundation

/// Internal HTTP client for Sezzle API requests.
///
/// Handles Basic auth, Sezzle-Platform header, and JSON encoding/decoding.
struct HTTPClient: Sendable {
    let publicKey: String
    let environment: SezzleEnvironment
    let session: URLSession
    internal static let sdkVersion = "1.2.1"

    init(publicKey: String, environment: SezzleEnvironment, session: URLSession = .shared) {
        self.publicKey = publicKey
        self.environment = environment
        self.session = session
    }

    /// Build the Basic auth header value: `Basic {base64(publicKey)}`
    var authorizationHeader: String {
        let encoded = Data(publicKey.utf8).base64EncodedString()
        return "Basic \(encoded)"
    }

    /// Build the Sezzle-Platform header: base64-encoded JSON with id, version, plugin_version.
    var platformHeader: String {
        let platform: [String: String] = [
            "id": "mobile-sdk-ios",
            "version": Self.sdkVersion,
            "plugin_version": Self.sdkVersion
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: platform)
        return jsonData.base64EncodedString()
    }

    /// Send a POST request with JSON body and decode the response.
    func post<Request: Encodable, Response: Decodable>(
        path: String,
        body: Request
    ) async throws(SezzleError) -> Response {
        let url = environment.gatewayURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        request.setValue(platformHeader, forHTTPHeaderField: "Sezzle-Platform")

        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw .invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw .networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = parseErrorMessage(from: data) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw .apiError(statusCode: httpResponse.statusCode, message: message)
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw .invalidResponse
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        // Gateway returns errors as an array: [{"code":"...", "message":"..."}]
        if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let first = array.first {
            return first["message"] as? String
        }
        // Fallback: single error object {"message":"..."}
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return dict["message"] as? String
        }
        return nil
    }
}
