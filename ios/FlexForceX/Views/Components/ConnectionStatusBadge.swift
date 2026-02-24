import SwiftUI

struct ConnectionStatusBadge: View {
  let status: TerraConnectionState

  private var color: Color {
    switch status {
    case .connected:
      return Theme.ColorPalette.success
    case .pending:
      return Theme.ColorPalette.warning
    case .error:
      return Theme.ColorPalette.danger
    case .disconnected:
      return .gray
    }
  }

  var body: some View {
    HStack(spacing: Theme.Spacing.sm) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
      Text(status.rawValue.capitalized)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(color)
    }
    .padding(.horizontal, Theme.Spacing.md)
    .padding(.vertical, Theme.Spacing.sm)
    .background(color.opacity(0.12))
    .clipShape(Capsule())
  }
}
