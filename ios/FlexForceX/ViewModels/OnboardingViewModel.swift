import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
  @Published var connection: TerraConnection?
  @Published var isLoading = false
  @Published var isConnecting = false
  @Published var connectURL: URL?
  @Published var errorMessage: String?

  private unowned let appViewModel: AppViewModel
  private let edgeFunctionsClient: EdgeFunctionsClient

  init(appViewModel: AppViewModel, edgeFunctionsClient: EdgeFunctionsClient) {
    self.appViewModel = appViewModel
    self.edgeFunctionsClient = edgeFunctionsClient
  }

  func load() {
    Task {
      await refreshConnectionStatus()
    }
  }

  func refreshConnectionStatus() async {
    guard let session = appViewModel.session else { return }
    isLoading = true
    defer { isLoading = false }

    do {
      let status = try await edgeFunctionsClient.getTerraStatus(accessToken: session.accessToken)
      connection = status
    } catch let error as AppError {
      errorMessage = error.userSafeMessage
    } catch {
      errorMessage = "Unable to fetch connection status."
    }
  }

  func beginTerraConnect() {
    guard let session = appViewModel.session else { return }
    isConnecting = true
    errorMessage = nil

    Task {
      defer { isConnecting = false }
      do {
        let response = try await edgeFunctionsClient.startTerraConnect(accessToken: session.accessToken)
        connection = TerraConnection(
          provider: response.provider,
          status: response.status,
          connectedAt: nil,
          lastSyncAt: nil,
          terraUserID: response.terraUserID
        )
        if let connectURL = response.connectURL, let url = URL(string: connectURL) {
          self.connectURL = url
        } else {
          errorMessage = "Could not launch Terra connect flow."
        }
      } catch let error as AppError {
        errorMessage = error.userSafeMessage
      } catch {
        errorMessage = "Could not start connect flow."
      }
    }
  }

  func completeOnboarding() {
    appViewModel.completeOnboarding()
  }
}
