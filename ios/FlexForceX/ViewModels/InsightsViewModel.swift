import Foundation

@MainActor
final class InsightsViewModel: ObservableObject {
  enum Range: Int, CaseIterable, Identifiable {
    case week = 7
    case month = 30

    var id: Int { rawValue }
    var label: String { self == .week ? "7D" : "30D" }
  }

  @Published var selectedRange: Range = .week
  @Published var biometrics: [BiometricsDaily] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private unowned let appViewModel: AppViewModel
  private let databaseClient: SupabaseDatabaseClient
  private let cache = BiometricsCache()

  init(appViewModel: AppViewModel, databaseClient: SupabaseDatabaseClient) {
    self.appViewModel = appViewModel
    self.databaseClient = databaseClient
  }

  func load() {
    guard let session = appViewModel.session else { return }
    isLoading = true

    Task {
      defer { isLoading = false }
      let days = selectedRange.rawValue
      if let cached = await cache.get(days: days) {
        biometrics = cached
      }

      do {
        let rows = try await databaseClient.fetchBiometricsDaily(
          accessToken: session.accessToken,
          days: days
        )
        biometrics = rows
        await cache.set(days: days, values: rows)
      } catch let error as AppError {
        errorMessage = error.userSafeMessage
      } catch {
        errorMessage = "Could not load insights."
      }
    }
  }
}
