import Foundation

final class SessionStore {
  private let keychain: KeychainStore
  private let sessionKey = "auth_session"

  init(keychain: KeychainStore) {
    self.keychain = keychain
  }

  func save(session: AuthSession) throws {
    let data = try JSONEncoder().encode(session)
    try keychain.set(data, for: sessionKey)
  }

  func load() throws -> AuthSession? {
    guard let data = try keychain.data(for: sessionKey) else {
      return nil
    }
    return try JSONDecoder().decode(AuthSession.self, from: data)
  }

  func clear() {
    keychain.remove(sessionKey)
  }
}
