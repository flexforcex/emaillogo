import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
  @Published var profile: Profile?
  @Published var connection: TerraConnection?
  @Published var isLoading = false
  @Published var message: String?
  @Published var errorMessage: String?

  private unowned let appViewModel: AppViewModel
  private let databaseClient: SupabaseDatabaseClient
  private let edgeFunctionsClient: EdgeFunctionsClient

  init(
    appViewModel: AppViewModel,
    databaseClient: SupabaseDatabaseClient,
    edgeFunctionsClient: EdgeFunctionsClient
  ) {
    self.appViewModel = appViewModel
    self.databaseClient = databaseClient
    self.edgeFunctionsClient = edgeFunctionsClient
  }

  func load() {
    guard let session = appViewModel.session else { return }
    isLoading = true
    errorMessage = nil

    Task {
      defer { isLoading = false }
      do {
        async let profileRequest = databaseClient.fetchProfile(
          accessToken: session.accessToken,
          userID: session.userID
        )
        async let connectionRequest = edgeFunctionsClient.getTerraStatus(accessToken: session.accessToken)
        profile = try await profileRequest
        connection = try await connectionRequest
      } catch let error as AppError {
        errorMessage = error.userSafeMessage
      } catch {
        errorMessage = "Unable to load settings."
      }
    }
  }

  func disconnectAppleHealth() {
    guard let session = appViewModel.session else { return }
    Task {
      do {
        try await databaseClient.disconnectTerra(accessToken: session.accessToken)
        connection = TerraConnection(
          provider: "apple_health",
          status: .disconnected,
          connectedAt: nil,
          lastSyncAt: nil,
          terraUserID: connection?.terraUserID
        )
        message = "Apple Health connection has been disconnected."
      } catch let error as AppError {
        errorMessage = error.userSafeMessage
      } catch {
        errorMessage = "Could not disconnect right now."
      }
    }
  }

  func requestExport() {
    guard let session = appViewModel.session else { return }
    Task {
      do {
        try await databaseClient.insertAuditEvent(
          accessToken: session.accessToken,
          eventType: "user.export.requested",
          payload: [
            "requested_at": ISO8601DateFormatter().string(from: Date()),
            "source": "ios_settings"
          ]
        )
        message = "Export request submitted. Support will follow up."
      } catch {
        errorMessage = "Could not submit export request."
      }
    }
  }

  func reportIssue(summary: String) {
    Task {
      await appViewModel.reportIssue(
        category: "user_feedback",
        message: summary,
        details: [
          "screen": "settings"
        ]
      )
      if let errorID = appViewModel.lastReportedErrorID {
        message = "Issue reported. Reference ID: \(errorID)"
      } else {
        message = "Issue report submitted."
      }
    }
  }
}
