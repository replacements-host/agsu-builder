import SwiftUI

struct MeasurementOverlayView: View {
    let placedItems: [PlacedItem]
    let selectedItem: PlacedItem?
    let canvasSize: CGSize
    let isVisible: Bool

    var body: some View {
        ZStack {
            if isVisible, let item = selectedItem {
                ForEach(Array(item.measurements.enumerated()), id: \.offset) { idx, measurement in
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

struct MeasurementCallout: View {
    let label: String
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
