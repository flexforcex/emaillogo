import SwiftUI

@main
struct FlexForceXApp: App {
  private let dependencies: AppDependencies
  @StateObject private var appViewModel: AppViewModel

  init() {
    let dependencies = AppDependencies(config: AppConfig.shared)
    self.dependencies = dependencies
    _appViewModel = StateObject(wrappedValue: AppViewModel(dependencies: dependencies))
  }

  var body: some Scene {
    WindowGroup {
      RootView(appViewModel: appViewModel, dependencies: dependencies)
        .task {
          appViewModel.bootstrap()
        }
        .onOpenURL { url in
          appViewModel.handleDeepLink(url)
        }
    }
  }
}
