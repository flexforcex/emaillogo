import Foundation

final class SupabaseAuthClient {
  private let transport: HTTPTransport

  init(transport: HTTPTransport) {
    self.transport = transport
  }

  func signIn(email: String, password: String) async throws -> AuthSession {
    let body: [String: Any] = [
      "email": email,
      "password": password
    ]
    let data = try await transport.authRequest(
      path: "/token",
      method: "POST",
      query: [URLQueryItem(name: "grant_type", value: "password")],
      body: body
    )
    return try parseSession(data: data)
  }

  func signUp(email: String, password: String, name: String) async throws -> AuthSession {
    let body: [String: Any] = [
      "email": email,
      "password": password,
      "data": ["name": name]
    ]
    let data = try await transport.authRequest(path: "/signup", method: "POST", body: body)
    return try parseSession(data: data)
  }

  func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession {
    let body: [String: Any] = [
      "provider": "apple",
      "id_token": idToken,
      "nonce": nonce
    ]
    let data = try await transport.authRequest(
      path: "/token",
      method: "POST",
      query: [URLQueryItem(name: "grant_type", value: "id_token")],
      body: body
    )
    return try parseSession(data: data)
  }

  func refreshSession(refreshToken: String) async throws -> AuthSession {
    let data = try await transport.authRequest(
      path: "/token",
      method: "POST",
      query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
      body: ["refresh_token": refreshToken]
    )
    return try parseSession(data: data)
  }

  func signOut(accessToken: String) async throws {
    _ = try await transport.authRequest(path: "/logout", method: "POST", accessToken: accessToken)
  }

  private func parseSession(data: Data) throws -> AuthSession {
    do {
      let response = try JSONDecoder().decode(AuthResponse.self, from: data)
      let expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
      return AuthSession(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresAt: expiresAt,
        userID: response.user.id,
        email: response.user.email
      )
    } catch {
      throw AppError.decoding("Could not decode authentication response.")
    }
  }
}

private struct AuthResponse: Decodable {
  let accessToken: String
  let refreshToken: String
  let expiresIn: Int
  let user: AuthUser

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case expiresIn = "expires_in"
    case user
  }
}

private struct AuthUser: Decodable {
  let id: String
  let email: String?
}
