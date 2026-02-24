import SwiftUI

struct DashboardView: View {
  @StateObject private var viewModel: DashboardViewModel

  init(viewModel: DashboardViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
          readinessCard
          connectionCard
          metricsGrid
          dailyPlanCard
        }
        .padding(Theme.Spacing.md)
      }
      .navigationTitle("Dashboard")
      .refreshable {
        viewModel.load(forceRefresh: true)
      }
      .onAppear {
        viewModel.load()
      }
      .alert("Update", isPresented: Binding(
        get: { viewModel.errorMessage != nil },
        set: { _ in viewModel.errorMessage = nil }
      )) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
    }
  }

  private var readinessCard: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
      Text("Readiness")
        .font(.headline)
      Text("\(viewModel.readinessScore)")
        .font(.system(size: 48, weight: .bold, design: .rounded))
      Text("Score updates after each Terra sync.")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Theme.Spacing.lg)
    .background(Theme.ColorPalette.card)
    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
  }

  private var connectionCard: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
      Text("Apple Health connection")
        .font(.headline)
      if let status = viewModel.connection?.status {
        ConnectionStatusBadge(status: status)
      } else {
        Text("No connection yet")
          .foregroundStyle(.secondary)
      }

      Text("Last sync: \(formattedSyncDate(viewModel.connection?.lastSyncAt))")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Theme.Spacing.md)
    .background(Theme.ColorPalette.card)
    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
  }

  private var metricsGrid: some View {
    let latest = viewModel.latestMetric
    return VStack(spacing: Theme.Spacing.md) {
      HStack(spacing: Theme.Spacing.md) {
        MetricTileView(
          title: "Sleep",
          value: "\(latest?.sleepMinutes ?? 0)m",
          subtitle: "Last day",
          systemImage: "bed.double.fill"
        )
        MetricTileView(
          title: "HRV",
          value: latest?.hrv.map { String(format: "%.1f", $0) } ?? "--",
          subtitle: "ms",
          systemImage: "waveform.path.ecg"
        )
      }
      HStack(spacing: Theme.Spacing.md) {
        MetricTileView(
          title: "Steps",
          value: "\(latest?.steps ?? 0)",
          subtitle: "count",
          systemImage: "figure.walk"
        )
        MetricTileView(
          title: "Active",
          value: "\(latest?.activeMinutes ?? 0)m",
          subtitle: "minutes",
          systemImage: "flame.fill"
        )
      }
    }
  }

  private var dailyPlanCard: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
      Text("Daily Plan")
        .font(.headline)
      Text("Plan generation is enabled for later trial phases.")
        .foregroundStyle(.secondary)
      Text("Coming soon")
        .font(.subheadline.weight(.semibold))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Theme.Spacing.md)
    .background(Theme.ColorPalette.card)
    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
  }

  private func formattedSyncDate(_ isoString: String?) -> String {
    guard
      let isoString,
      let date = ISO8601DateFormatter().date(from: isoString)
    else {
      return "Never"
    }
    return date.formatted(date: .abbreviated, time: .shortened)
  }
}
