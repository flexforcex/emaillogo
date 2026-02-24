import Foundation

enum TerraConnectionState: String, Codable {
  case pending
  case connected
  case error
  case disconnected
}

struct TerraConnection: Decodable {
  let provider: String
  let status: TerraConnectionState
  let connectedAt: String?
  let lastSyncAt: String?
  let terraUserID: String?

  enum CodingKeys: String, CodingKey {
    case provider
    case status
    case connectedAt = "connected_at"
    case lastSyncAt = "last_sync_at"
    case terraUserID = "terra_user_id"
  }
}
