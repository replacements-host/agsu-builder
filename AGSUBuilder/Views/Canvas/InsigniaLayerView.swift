import SwiftUI

/// Transparent overlay that positions all `PlacedItem` views over the coat canvas.
///
/// This view sits above `CoatLayerView` in the `ZStack` inside `CanvasView`.
/// Each item is rendered by `InsigniaItemView` at absolute coordinates derived from
/// the item's `effectivePosition` (normalized 0–1) multiplied by `canvasSize`.
struct InsigniaLayerView: View {

    /// All placed items output by the last `PlacementEngine` run.
    let placedItems: [PlacedItem]
    /// The currently selected item's `id`; drives the gold selection ring overlay.
    let selectedItemID: String?
    /// Frame of the canvas in SwiftUI points — used to convert normalized to pixel coords.
    let canvasSize: CGSize

    var body: some View {
        ZStack {
            ForEach(placedItems) { item in
                InsigniaItemView(
                    item:         item,
                    isSelected:   item.id == selectedItemID,
                    canvasSize:   canvasSize
                )
            }
        }
    }
}

// MARK: - InsigniaItemView

/// Renders a single placed item as either its catalog image or a colored placeholder.
///
/// **Placeholder color coding by category:**
/// - Ribbon → blue  |  Badge → green  |  ID Badge → purple
/// - Tab → orange   |  Rank → yellow  |  Branch → teal  |  US → red
///
/// **Overlays:**
/// - Gold ring: appears when `isSelected == true`; 1-pt wider than the item frame.
/// - Amber dot: appears when `item.isOutOfPolicy == true`; top-right corner of the frame.
struct InsigniaItemView: View {

    let item:       PlacedItem
    let isSelected: Bool
    let canvasSize: CGSize

    /// Converts the item's normalized effective position to SwiftUI canvas points.
    private var pixelPosition: CGPoint {
        CGPoint(
            x: item.effectivePosition.x * canvasSize.width,
            y: item.effectivePosition.y * canvasSize.height
        )
    }

    /// Converts the item's normalized render size to SwiftUI canvas points.
    private var pixelSize: CGSize {
        CGSize(
            width:  item.renderSize.width  * canvasSize.width,
            height: item.renderSize.height * canvasSize.height
        )
    }

    var body: some View {
        Group {
            if let img = UIImage(named: item.item.id) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            } else {
                // Colored placeholder rectangle for items without artwork
                placeholderView
            }
        }
        .frame(width: max(pixelSize.width, 8), height: max(pixelSize.height, 8))
        .rotationEffect(item.effectiveRotation)
        .position(pixelPosition)
        // Gold selection ring
        .overlay(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.brandGold, lineWidth: 1)
                        .opacity(0.8)
                        .frame(
                            width:  max(pixelSize.width,  8) + 4,
                            height: max(pixelSize.height, 8) + 4
                        )
                }
            }
        )
        // Amber out-of-policy dot (top-right corner)
        .overlay(
            Group {
                if item.isOutOfPolicy {
                    Circle()
                        .fill(Color.brandAmber)
                        .frame(width: 8, height: 8)
                        .offset(
                            x: max(pixelSize.width,  8) / 2 - 2,
                            y: -max(pixelSize.height, 8) / 2 + 2
                        )
                }
            }
        )
    }

    /// Semi-transparent colored rectangle used when the real insignia image is absent.
    @ViewBuilder
    private var placeholderView: some View {
        let color = colorForCategory(item.item.category)
        RoundedRectangle(cornerRadius: 2)
            .fill(color.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(color, lineWidth: 0.5)
            )
    }

    /// Maps an `ItemCategory` to a distinct debug color for placeholder rendering.
    private func colorForCategory(_ category: ItemCategory) -> Color {
        switch category {
        case .ribbon:           return Color(.systemBlue)
        case .badge:            return Color(.systemGreen)
        case .idBadge:          return Color(.systemPurple)
        case .tab:              return Color(.systemOrange)
        case .rank:             return Color(.systemYellow)
        case .branchInsignia:   return Color(.systemTeal)
        case .usInsignia:       return Color(.systemRed)
        default:                return Color(.systemGray)
        }
    }
}
