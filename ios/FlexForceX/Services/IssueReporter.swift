import Foundation

final class IssueReporter {
  private let databaseClient: SupabaseDatabaseClient

  init(databaseClient: SupabaseDatabaseClient) {
    self.databaseClient = databaseClient
  }

  @discardableResult
  func report(
    accessToken: String,
    userID: String,
    category: String,
    message: String,
    details: [String: String] = [:]
  ) async -> String {
    let errorID = UUID().uuidString.lowercased()
    let payload: [String: Any] = [
      "error_id": errorID,
      "category": category,
      "message": message,
      "details": details,
      "platform": "ios",
      "user_id": userID
    ]
    do {
      try await databaseClient.insertAuditEvent(
        accessToken: accessToken,
        eventType: "app.issue.reported",
        payload: payload
      )
    } catch {
      // Keep reporting non-blocking for user flows.
    }
    return errorID
  }
}
