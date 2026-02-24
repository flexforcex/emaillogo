import Foundation

final class SupabaseDatabaseClient {
  private let transport: HTTPTransport

  init(transport: HTTPTransport) {
    self.transport = transport
  }

  func fetchProfile(accessToken: String, userID: String) async throws -> Profile? {
    let query = [
      URLQueryItem(name: "user_id", value: "eq.\(userID)"),
      URLQueryItem(name: "select", value: "user_id,name,dob,trial_cohort,created_at"),
      URLQueryItem(name: "limit", value: "1")
    ]
    let data = try await transport.restRequest(
      path: "/profiles",
      method: "GET",
      accessToken: accessToken,
      query: query
    )
    return try decodeArray(data, as: Profile.self).first
  }

  func upsertProfile(accessToken: String, userID: String, name: String) async throws {
    let body: [String: Any] = [
      "user_id": userID,
      "name": name
    ]
    _ = try await transport.restRequest(
      path: "/profiles",
      method: "POST",
      accessToken: accessToken,
      body: body,
      prefer: "resolution=merge-duplicates,return=minimal"
    )
  }

  func fetchBiometricsDaily(accessToken: String, days: Int) async throws -> [BiometricsDaily] {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    let sinceDate = Calendar.current.date(byAdding: .day, value: -max(days - 1, 0), to: Date()) ?? Date()
    let sinceDateString = formatter.string(from: sinceDate)

    let query = [
      URLQueryItem(name: "select", value: "user_id,date,steps,sleep_minutes,hrv,rhr,calories,active_minutes,updated_at"),
      URLQueryItem(name: "date", value: "gte.\(sinceDateString)"),
      URLQueryItem(name: "order", value: "date.asc")
    ]
    let data = try await transport.restRequest(
      path: "/biometrics_daily",
      method: "GET",
      accessToken: accessToken,
      query: query
    )
    return try decodeArray(data, as: BiometricsDaily.self)
  }

  func fetchTerraConnection(accessToken: String) async throws -> TerraConnection? {
    let query = [
      URLQueryItem(name: "provider", value: "eq.apple_health"),
      URLQueryItem(name: "select", value: "provider,status,connected_at,last_sync_at,terra_user_id"),
      URLQueryItem(name: "limit", value: "1")
    ]
    let data = try await transport.restRequest(
      path: "/terra_connections",
      method: "GET",
      accessToken: accessToken,
      query: query
    )
    return try decodeArray(data, as: TerraConnection.self).first
  }

  func disconnectTerra(accessToken: String) async throws {
    _ = try await transport.restRequest(
      path: "/terra_connections",
      method: "PATCH",
      accessToken: accessToken,
      query: [URLQueryItem(name: "provider", value: "eq.apple_health")],
      body: [
        "status": "disconnected",
        "last_sync_at": NSNull()
      ],
      prefer: "return=minimal"
    )
  }

  func insertAuditEvent(
    accessToken: String,
    eventType: String,
    payload: [String: Any]
  ) async throws {
    _ = try await transport.restRequest(
      path: "/events_audit",
      method: "POST",
      accessToken: accessToken,
      body: [
        "event_type": eventType,
        "payload": payload
      ],
      prefer: "return=minimal"
    )
  }

  private func decodeArray<T: Decodable>(_ data: Data, as type: T.Type) throws -> [T] {
    do {
      return try JSONDecoder().decode([T].self, from: data)
    } catch {
      throw AppError.decoding("Failed to decode server response.")
    }
  }
}
