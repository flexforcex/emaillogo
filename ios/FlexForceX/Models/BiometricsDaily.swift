import Foundation

struct BiometricsDaily: Decodable, Identifiable {
  let userID: String
  let date: String
  let steps: Int
  let sleepMinutes: Int
  let hrv: Double?
  let rhr: Double?
  let calories: Int
  let activeMinutes: Int
  let updatedAt: String

  var id: String { "\(userID)-\(date)" }

  enum CodingKeys: String, CodingKey {
    case userID = "user_id"
    case date
    case steps
    case sleepMinutes = "sleep_minutes"
    case hrv
    case rhr
    case calories
    case activeMinutes = "active_minutes"
    case updatedAt = "updated_at"
  }
}
