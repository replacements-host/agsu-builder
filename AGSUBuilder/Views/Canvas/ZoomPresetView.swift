import SwiftUI

struct ZoomPresetView: View {
    let currentZone: ZoomZone
    let onSelect: (ZoomZone) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(ZoomZone.allCases, id: \.self) { zone in
                    Button(action: { onSelect(zone) }) {
                        Text(zone.rawValue.uppercased())
                            .font(AppFont.semiBold(12))
                            .foregroundColor(zone == currentZone ? .black : Color(.secondaryLabel))
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(zone == currentZone ? Color.brandGold : Color(.secondarySystemBackground))
                            .cornerRadius(Radius.lg)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.sm)
    }
}
