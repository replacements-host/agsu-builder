import SwiftUI

/// Horizontal scrolling strip of zoom preset buttons rendered below the coat canvas.
///
/// Each button maps to a `ZoomZone` case. The active zone is highlighted
/// with a brandGold background; inactive zones use the secondary system background.
/// Tapping calls `onSelect` which triggers an animated zoom in `CanvasViewModel.zoomTo(_:)`.
struct ZoomPresetView: View {

    /// The currently active zoom zone, used to highlight the selected button.
    let currentZone: ZoomZone
    /// Callback invoked when the user taps a zone button.
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
