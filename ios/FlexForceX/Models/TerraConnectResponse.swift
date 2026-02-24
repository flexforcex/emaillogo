import Foundation

struct TerraConnectResponse: Decodable {
  let provider: String
  let terraUserID: String
  let status: TerraConnectionState
  let connectURL: String?
  let connectToken: String?
  let redirectURL: String?

  enum CodingKeys: String, CodingKey {
    case provider
    case terraUserID = "terra_user_id"
    case status
    case connectURL = "connect_url"
    case connectToken = "connect_token"
    case redirectURL = "redirect_url"
  }
}
