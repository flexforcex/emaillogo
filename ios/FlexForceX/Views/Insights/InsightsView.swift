import Charts
import SwiftUI

struct InsightsView: View {
  @StateObject private var viewModel: InsightsViewModel

  init(viewModel: InsightsViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: Theme.Spacing.md) {
        Picker("Range", selection: $viewModel.selectedRange) {
          ForEach(InsightsViewModel.Range.allCases) { range in
            Text(range.label).tag(range)
          }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.md)
        .onChange(of: viewModel.selectedRange) { _, _ in
          viewModel.load()
        }

        if viewModel.isLoading {
          ProgressView("Loading insights...")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if viewModel.biometrics.isEmpty {
          ContentUnavailableView(
            "No data yet",
            systemImage: "chart.line.uptrend.xyaxis",
            description: Text("Connect Apple Health to populate insight trends.")
          )
        } else {
          ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
              metricChart(
                title: "Steps trend",
                points: viewModel.biometrics.map { ($0.date, Double($0.steps)) },
                color: .blue
              )
              metricChart(
                title: "Sleep trend (minutes)",
                points: viewModel.biometrics.map { ($0.date, Double($0.sleepMinutes)) },
                color: .purple
              )
              metricChart(
                title: "Active minutes trend",
                points: viewModel.biometrics.map { ($0.date, Double($0.activeMinutes)) },
                color: .green
              )
            }
            .padding(Theme.Spacing.md)
          }
        }
      }
      .navigationTitle("Insights")
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

  private func metricChart(
    title: String,
    points: [(date: String, value: Double)],
    color: Color
  ) -> some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
      Text(title)
        .font(.headline)
      Chart(points, id: \.date) { point in
        LineMark(
          x: .value("Date", point.date),
          y: .value("Value", point.value)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(color)
      }
      .frame(height: 220)
    }
    .padding(Theme.Spacing.md)
    .background(Theme.ColorPalette.card)
    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
  }
}
