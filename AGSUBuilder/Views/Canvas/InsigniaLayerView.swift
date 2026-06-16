import SwiftUI

struct InsigniaLayerView: View {
    let placedItems: [PlacedItem]
    let selectedItemID: String?
    let canvasSize: CGSize

    var body: some View {
        ZStack {
            ForEach(placedItems) { item in
                InsigniaItemView(
                    item: item,
                    isSelected: item.id == selectedItemID,
                    canvasSize: canvasSize
                )
            }
        }
    }
}

struct InsigniaItemView: View {
    let item: PlacedItem
    let isSelected: Bool
    let canvasSize: CGSize

    private var pixelPosition: CGPoint {
        CGPoint(
            x: item.effectivePosition.x * canvasSize.width,
            y: item.effectivePosition.y * canvasSize.height
        )
    }

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
                // Placeholder colored rectangle for missing images
                placeholderView
            }
        }
        .frame(width: max(pixelSize.width, 8), height: max(pixelSize.height, 8))
        .rotationEffect(item.effectiveRotation)
        .position(pixelPosition)
        .overlay(
            // Selection highlight ring
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.brandGold, lineWidth: 1)
                        .opacity(0.8)
                        .frame(width: max(pixelSize.width, 8) + 4, height: max(pixelSize.height, 8) + 4)
                }
            }
        )
        .overlay(
            // Out-of-policy amber indicator
            Group {
                if item.isOutOfPolicy {
                    Circle()
                        .fill(Color.brandAmber)
                        .frame(width: 8, height: 8)
                        .offset(x: max(pixelSize.width, 8) / 2 - 2, y: -max(pixelSize.height, 8) / 2 + 2)
                }
            }
        )
    }

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
