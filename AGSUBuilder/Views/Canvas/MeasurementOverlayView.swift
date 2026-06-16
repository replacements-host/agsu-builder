import SwiftUI

/// Transparent overlay that renders measurement callout chips above placed items.
///
/// Visible only when `isVisible == true` (toggled by the "REGS" toolbar button in
/// `CanvasView`). When a `selectedItem` is present, one `MeasurementCallout` chip
/// is rendered for each entry in `selectedItem.measurements`, stacked 20 pt apart
/// above the item's canvas position.
struct MeasurementOverlayView: View {

    let placedItems:  [PlacedItem]
    /// The currently selected item, or `nil` when nothing is selected.
    let selectedItem: PlacedItem?
    /// Canvas frame in SwiftUI points — used to convert normalized positions.
    let canvasSize:   CGSize
    /// Controlled by the "REGS" toolbar button; hides overlay when `false`.
    let isVisible:    Bool

    var body: some View {
        ZStack {
            if isVisible, let item = selectedItem {
                ForEach(Array(item.measurements.enumerated()), id: \.offset) { idx, measurement in
                    // Stack callouts upward from the item center, 20 pt per step
                    let yOffset = CGFloat(idx) * 20.0 + 12
                    let pos = CGPoint(
                        x: item.effectivePosition.x * canvasSize.width,
                        y: item.effectivePosition.y * canvasSize.height - yOffset
                    )
                    MeasurementCallout(label: measurement.label, value: measurement.value)
                        .position(pos)
                }
            }
        }
    }
}

// MARK: - MeasurementCallout

/// A pill-shaped chip showing a measurement label (gold) and value (primary).
///
/// Used exclusively by `MeasurementOverlayView`. The semi-opaque background
/// ensures legibility against both light and dark coat imagery.
struct MeasurementCallout: View {

    /// Short label, e.g. "Position" or "Rows". Rendered in `AppFont.caption` uppercase.
    let label: String
    /// Value string, e.g. "1/8\" above left breast pocket". Rendered in `AppFont.measurement`.
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label.uppercased())
                .font(AppFont.caption)
                .foregroundColor(.brandGold)
            Text(value)
                .font(AppFont.measurement)
                .foregroundColor(Color(.label))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(4)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.brandGold.opacity(0.4), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.15), radius: 2)
    }
}
