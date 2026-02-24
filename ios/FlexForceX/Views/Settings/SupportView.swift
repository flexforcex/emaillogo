import SwiftUI

struct SupportView: View {
  var body: some View {
    List {
      Section("Support") {
        LabeledContent("Email", value: "support@flexforcex.com")
        LabeledContent("Trial Hotline", value: "+1-800-555-0140")
      }
      Section("What to include") {
        Text("Include your issue reference ID, device model, and approximate time of issue.")
      }
    }
    .navigationTitle("Support")
  }
}
