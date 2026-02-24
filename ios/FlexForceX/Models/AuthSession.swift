import Foundation

struct AuthSession: Codable {
  let accessToken: String
  let refreshToken: String
  let expiresAt: Date
  let userID: String
  let email: String?

  var isExpired: Bool {
    Date() >= expiresAt.addingTimeInterval(-60)
  }
}
