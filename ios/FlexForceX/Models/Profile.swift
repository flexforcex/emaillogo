import Foundation

struct Profile: Decodable, Identifiable {
  let userID: String
  let name: String
  let dob: String?
  let trialCohort: String
  let createdAt: String

  var id: String { userID }

  enum CodingKeys: String, CodingKey {
    case userID = "user_id"
    case name
    case dob
    case trialCohort = "trial_cohort"
    case createdAt = "created_at"
  }
}
