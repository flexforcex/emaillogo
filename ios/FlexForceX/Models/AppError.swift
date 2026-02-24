import Foundation

enum AppError: LocalizedError {
  case configuration(String)
  case network(String)
  case decoding(String)
  case authentication(String)
  case validation(String)
  case unknown(String)

  var errorDescription: String? {
    switch self {
    case .configuration(let message),
        .network(let message),
        .decoding(let message),
        .authentication(let message),
        .validation(let message),
        .unknown(let message):
      return message
    }
  }

  var userSafeMessage: String {
    switch self {
    case .configuration:
      return "App configuration is incomplete. Please contact support."
    case .network:
      return "Unable to reach the server. Please try again."
    case .decoding:
      return "We could not process server data. Please retry in a moment."
    case .authentication:
      return "Your session expired. Please sign in again."
    case .validation(let message):
      return message
    case .unknown:
      return "Something went wrong. Please try again."
    }
  }
}
