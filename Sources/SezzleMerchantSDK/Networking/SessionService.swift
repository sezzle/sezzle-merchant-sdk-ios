import Foundation

/// Protocol for session creation, allowing mock injection in tests.
protocol SessionServiceProtocol: Sendable {
    func createSession(checkout: SezzleCheckout) async throws(SezzleError) -> SessionResponse
}

/// Creates a Sezzle checkout session via `POST /v2/session`.
struct SessionService: SessionServiceProtocol {
    let httpClient: HTTPClient

    func createSession(checkout: SezzleCheckout) async throws(SezzleError) -> SessionResponse {
        let request = SessionRequest.from(checkout)
        return try await httpClient.post(path: "/v2/session", body: request)
    }
}
