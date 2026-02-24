import Foundation

struct AppConfig {
  let supabaseURL: URL
  let supabaseAnonKey: String
  let deepLinkScheme: String

  static let shared = AppConfig()

  init(bundle: Bundle = .main) {
    let supabaseURLString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ??
      ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
    let anonKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ??
      ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
    let scheme = bundle.object(forInfoDictionaryKey: "APP_DEEP_LINK_SCHEME") as? String ??
      ProcessInfo.processInfo.environment["APP_DEEP_LINK_SCHEME"] ?? "flexforcex"

    guard let url = URL(string: supabaseURLString), !supabaseURLString.isEmpty else {
      fatalError("SUPABASE_URL is not configured.")
    }
    guard !anonKey.isEmpty else {
      fatalError("SUPABASE_ANON_KEY is not configured.")
    }

    self.supabaseURL = url
    self.supabaseAnonKey = anonKey
    self.deepLinkScheme = scheme
  }
}
