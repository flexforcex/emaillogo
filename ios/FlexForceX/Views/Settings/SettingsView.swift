import SwiftUI

struct SettingsView: View {
  @StateObject private var viewModel: SettingsViewModel
  @ObservedObject private var appViewModel: AppViewModel
  @State private var issueText = ""
  @State private var showIssuePrompt = false

  init(viewModel: SettingsViewModel, appViewModel: AppViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
    self.appViewModel = appViewModel
  }

  var body: some View {
    NavigationStack {
      List {
        Section("Profile") {
          LabeledContent("Name", value: viewModel.profile?.name ?? "—")
          LabeledContent("Cohort", value: viewModel.profile?.trialCohort ?? "—")
          LabeledContent(
            "Connection",
            value: viewModel.connection?.status.rawValue.capitalized ?? "Unknown"
          )
        }

        Section("Data permissions") {
          Button("Disconnect Apple Health", role: .destructive) {
            viewModel.disconnectAppleHealth()
          }
          Button("Request data export") {
            viewModel.requestExport()
          }
        }

        Section("Support") {
          Button("Report issue") {
            showIssuePrompt = true
          }
          NavigationLink("Contact support") {
            SupportView()
          }
        }

        Section {
          Button("Sign out", role: .destructive) {
            Task { await appViewModel.signOut() }
          }
        }
      }
      .navigationTitle("Settings")
      .onAppear {
        viewModel.load()
      }
      .alert("Report issue", isPresented: $showIssuePrompt) {
        TextField("Describe what happened", text: $issueText)
        Button("Submit") {
          viewModel.reportIssue(summary: issueText)
          issueText = ""
        }
        Button("Cancel", role: .cancel) {}
      }
      .alert("Notice", isPresented: Binding(
        get: { viewModel.message != nil || viewModel.errorMessage != nil },
        set: { _ in
          viewModel.message = nil
          viewModel.errorMessage = nil
        }
      )) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(viewModel.message ?? viewModel.errorMessage ?? "")
      }
    }
  }
}
