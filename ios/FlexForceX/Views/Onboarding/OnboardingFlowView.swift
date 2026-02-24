import SwiftUI

struct OnboardingFlowView: View {
  @StateObject private var viewModel: OnboardingViewModel
  let deepLinkPulse: Int

  @State private var step: Int = 0

  init(viewModel: OnboardingViewModel, deepLinkPulse: Int) {
    _viewModel = StateObject(wrappedValue: viewModel)
    self.deepLinkPulse = deepLinkPulse
  }

  var body: some View {
    VStack(spacing: Theme.Spacing.lg) {
      if step == 0 {
        consentStep
      } else {
        connectStep
      }
      Spacer(minLength: 0)
    }
    .padding(Theme.Spacing.lg)
    .onAppear {
      viewModel.load()
    }
    .onChange(of: deepLinkPulse) { _, _ in
      Task { await viewModel.refreshConnectionStatus() }
    }
    .sheet(item: Binding(
      get: { viewModel.connectURL.map(IdentifiableURL.init(url:)) },
      set: { _ in viewModel.connectURL = nil }
    )) { item in
      SafariSheetView(url: item.url)
    }
  }

  private var consentStep: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
      Text("Consent & data use")
        .font(.title2.weight(.bold))
      Text(
        """
        We use your wearable-derived health metrics to generate training and recovery insights.
        Data is stored securely in Supabase and used only for the Flex Force X trial.
        """
      )
      .foregroundStyle(.secondary)

      Button("I Understand and Consent") {
        step = 1
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var connectStep: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
      Text("Connect Apple Health")
        .font(.title2.weight(.bold))
      Text("Flex Force X connects through Terra to sync daily steps, HRV, sleep, and activity.")
        .foregroundStyle(.secondary)

      if let connection = viewModel.connection {
        ConnectionStatusBadge(status: connection.status)
      } else if viewModel.isLoading {
        ProgressView("Checking connection status...")
      }

      Button {
        viewModel.beginTerraConnect()
      } label: {
        if viewModel.isConnecting {
          ProgressView()
        } else {
          Text("Connect Apple Health")
            .frame(maxWidth: .infinity)
        }
      }
      .buttonStyle(.borderedProminent)

      Button("Refresh connection status") {
        Task { await viewModel.refreshConnectionStatus() }
      }
      .buttonStyle(.bordered)

      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .font(.footnote)
          .foregroundStyle(Theme.ColorPalette.danger)
      }

      Button("Continue to dashboard") {
        viewModel.completeOnboarding()
      }
      .buttonStyle(.borderedProminent)
      .tint(Theme.ColorPalette.success)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct IdentifiableURL: Identifiable {
  let id = UUID()
  let url: URL
}
