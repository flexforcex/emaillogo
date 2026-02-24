import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
  @Published var connection: TerraConnection?
  @Published var biometrics: [BiometricsDaily] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private unowned let appViewModel: AppViewModel
  private let edgeFunctionsClient: EdgeFunctionsClient
  private let databaseClient: SupabaseDatabaseClient
  private let cache = BiometricsCache()

  init(
    appViewModel: AppViewModel,
    edgeFunctionsClient: EdgeFunctionsClient,
    databaseClient: SupabaseDatabaseClient
  ) {
    self.appViewModel = appViewModel
    self.edgeFunctionsClient = edgeFunctionsClient
    self.databaseClient = databaseClient
  }

  var latestMetric: BiometricsDaily? {
    biometrics.last
  }

  var readinessScore: Int {
    guard let latest = latestMetric else { return 0 }
    var score = 50
    score += min(20, latest.sleepMinutes / 25)
    score += min(15, latest.activeMinutes / 4)
    if let hrv = latest.hrv {
      score += min(10, Int(hrv / 8))
    }
    if let rhr = latest.rhr, rhr < 60 {
      score += 5
    }
    return min(100, max(0, score))
  }

  func load(forceRefresh: Bool = false) {
    guard let session = appViewModel.session else { return }
    isLoading = true
    errorMessage = nil

    Task {
      defer { isLoading = false }

      if !forceRefresh, let cached = await cache.get(days: 30) {
        biometrics = cached
      }

      do {
        async let statusRequest = edgeFunctionsClient.getTerraStatus(accessToken: session.accessToken)
        async let dailyRequest = databaseClient.fetchBiometricsDaily(accessToken: session.accessToken, days: 30)

        connection = try await statusRequest
        let rows = try await dailyRequest
        biometrics = rows
        await cache.set(days: 30, values: rows)
      } catch let error as AppError {
        errorMessage = error.userSafeMessage
      } catch {
        errorMessage = "Unable to refresh dashboard."
      }
    }
  }
}
