import SwiftUI

struct RootView: View {
  @ObservedObject var appViewModel: AppViewModel
  let dependencies: AppDependencies

  var body: some View {
    Group {
      switch appViewModel.route {
      case .loading:
        ProgressView("Loading...")
      case .auth:
        AuthLandingView(
          viewModel: AuthViewModel(
            appViewModel: appViewModel,
            authClient: dependencies.authClient
          )
        )
      case .onboarding:
        OnboardingFlowView(
          viewModel: OnboardingViewModel(
            appViewModel: appViewModel,
            edgeFunctionsClient: dependencies.edgeFunctionsClient
          ),
          deepLinkPulse: appViewModel.deepLinkPulse
        )
      case .main:
        MainTabView(appViewModel: appViewModel, dependencies: dependencies)
      }
    }
    .background(Theme.ColorPalette.background)
  }
}

private struct MainTabView: View {
  @ObservedObject var appViewModel: AppViewModel
  let dependencies: AppDependencies

  var body: some View {
    TabView {
      DashboardView(
        viewModel: DashboardViewModel(
          appViewModel: appViewModel,
          edgeFunctionsClient: dependencies.edgeFunctionsClient,
          databaseClient: dependencies.databaseClient
        )
      )
      .tabItem {
        Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
      }

      InsightsView(
        viewModel: InsightsViewModel(
          appViewModel: appViewModel,
          databaseClient: dependencies.databaseClient
        )
      )
      .tabItem {
        Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
      }

      SettingsView(
        viewModel: SettingsViewModel(
          appViewModel: appViewModel,
          databaseClient: dependencies.databaseClient,
          edgeFunctionsClient: dependencies.edgeFunctionsClient
        ),
        appViewModel: appViewModel
      )
      .tabItem {
        Label("Settings", systemImage: "gearshape.fill")
      }
    }
  }
}
