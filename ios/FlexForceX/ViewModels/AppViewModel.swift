import Foundation

@MainActor
final class AppViewModel: ObservableObject {
  enum Route {
    case loading
    case auth
    case onboarding
    case main
  }

  @Published var route: Route = .loading
  @Published var session: AuthSession?
  @Published var profile: Profile?
  @Published var globalMessage: String?
  @Published var lastReportedErrorID: String?
  @Published var deepLinkPulse: Int = 0

  private let dependencies: AppDependencies

  init(dependencies: AppDependencies) {
    self.dependencies = dependencies
  }

  func bootstrap() {
    Task {
      do {
        guard var existing = try dependencies.sessionStore.load() else {
          route = .auth
          return
        }

        if existing.isExpired {
          existing = try await dependencies.authClient.refreshSession(
            refreshToken: existing.refreshToken
          )
          try dependencies.sessionStore.save(session: existing)
        }

        session = existing
        profile = try await dependencies.databaseClient.fetchProfile(
          accessToken: existing.accessToken,
          userID: existing.userID
        )

        let consentComplete = dependencies.consentStore.hasCompletedConsent(for: existing.userID)
        route = consentComplete ? .main : .onboarding
      } catch {
        dependencies.sessionStore.clear()
        session = nil
        route = .auth
      }
    }
  }

  func handleSuccessfulSignIn(session: AuthSession, userName: String) async {
    do {
      try dependencies.sessionStore.save(session: session)
      self.session = session
      let existingProfile = try await dependencies.databaseClient.fetchProfile(
        accessToken: session.accessToken,
        userID: session.userID
      )
      if existingProfile == nil {
        try await dependencies.databaseClient.upsertProfile(
          accessToken: session.accessToken,
          userID: session.userID,
          name: userName
        )
      }
      profile = try await dependencies.databaseClient.fetchProfile(
        accessToken: session.accessToken,
        userID: session.userID
      )
      route = dependencies.consentStore.hasCompletedConsent(for: session.userID) ? .main : .onboarding
    } catch {
      route = .auth
      globalMessage = "Sign in succeeded but profile setup failed. Please try again."
    }
  }

  func completeOnboarding() {
    guard let userID = session?.userID else { return }
    dependencies.consentStore.markConsentComplete(for: userID)
    route = .main
  }

  func handleDeepLink(_ url: URL) {
    guard url.scheme?.lowercased() == AppConfig.shared.deepLinkScheme else { return }
    deepLinkPulse += 1
  }

  func signOut() async {
    defer {
      dependencies.sessionStore.clear()
      session = nil
      profile = nil
      route = .auth
    }

    guard let accessToken = session?.accessToken else {
      return
    }
    try? await dependencies.authClient.signOut(accessToken: accessToken)
  }

  func reportIssue(category: String, message: String, details: [String: String] = [:]) async {
    guard let session else { return }
    let errorID = await dependencies.issueReporter.report(
      accessToken: session.accessToken,
      userID: session.userID,
      category: category,
      message: message,
      details: details
    )
    lastReportedErrorID = errorID
  }
}
