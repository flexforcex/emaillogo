import SwiftUI

struct MetricTileView: View {
  let title: String
  let value: String
  let subtitle: String
  let systemImage: String

  var body: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
      Label(title, systemImage: systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      Text(value)
        .font(.title3.weight(.bold))

      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Theme.Spacing.md)
    .background(Theme.ColorPalette.card)
    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
  }
}
