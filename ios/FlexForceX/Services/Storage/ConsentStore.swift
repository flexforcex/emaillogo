import Foundation

final class ConsentStore {
  private let defaults = UserDefaults.standard
  private let keyPrefix = "onboarding-consent"

  func hasCompletedConsent(for userID: String) -> Bool {
    defaults.bool(forKey: "\(keyPrefix)-\(userID)")
  }

  func markConsentComplete(for userID: String) {
    defaults.set(true, forKey: "\(keyPrefix)-\(userID)")
  }
}
