import SwiftUI
import Combine

enum ZoomZone: String, CaseIterable {
    case full = "Full"
    case leftChest = "Left Chest"
    case rightChest = "Right Chest"
    case sleeves = "Sleeves"
}

@MainActor
class CanvasViewModel: ObservableObject {
    @Published var soldier: Soldier
    @Published var selectedItems: [UniformItem]
    @Published var configuration: UniformConfiguration
    @Published var placedItems: [PlacedItem] = []
    @Published var selectedPlacedItem: PlacedItem? = nil
    @Published var zoomZone: ZoomZone = .full
    @Published var zoomScale: CGFloat = 1.0
    @Published var zoomOffset: CGSize = .zero

    private var engine: PlacementEngine {
        PlacementEngine(geometry: soldier.coatVariant.geometry, config: configuration)
    }

    init(soldier: Soldier, items: [UniformItem] = [], config: UniformConfiguration = UniformConfiguration()) {
        self.soldier = soldier
        self.selectedItems = items
        self.configuration = config
        recompute()
    }

    func recompute() {
        placedItems = engine.place(items: selectedItems, soldier: soldier)
    }

    func zoomTo(_ zone: ZoomZone) {
        withAnimation(.easeInOut(duration: 0.35)) {
            zoomZone = zone
            switch zone {
            case .full:
                zoomScale = 1.0
                zoomOffset = .zero
            case .leftChest:
                zoomScale = 2.2
                zoomOffset = CGSize(width: 60, height: -40)
            case .rightChest:
                zoomScale = 2.2
                zoomOffset = CGSize(width: -60, height: -40)
            case .sleeves:
                zoomScale = 1.6
                zoomOffset = CGSize(width: 0, height: 30)
            }
        }
    }

    func handleTap(at point: CGPoint, in canvasSize: CGSize) {
        // Convert tap point to normalized coordinates
        let normalized = CGPoint(x: point.x / canvasSize.width, y: point.y / canvasSize.height)
        // Find nearest placed item within a tap tolerance radius
        let tolerance: CGFloat = 0.05
        let nearest = placedItems.min(by: { a, b in
            let da = hypot(a.effectivePosition.x - normalized.x, a.effectivePosition.y - normalized.y)
            let db = hypot(b.effectivePosition.x - normalized.x, b.effectivePosition.y - normalized.y)
            return da < db
        })
        if let item = nearest {
            let dist = hypot(item.effectivePosition.x - normalized.x, item.effectivePosition.y - normalized.y)
            if dist < tolerance {
                selectedPlacedItem = item
            } else {
                selectedPlacedItem = nil
            }
        }
    }

    func moveItem(id: String, by delta: CGSize, snapInches: CGFloat) {
        guard let idx = placedItems.firstIndex(where: { $0.id == id }) else { return }
        let snapUnit = snapInches * soldier.coatVariant.geometry.normalizedUnitsPerInch
        let currentPos = placedItems[idx].adjustedPosition ?? placedItems[idx].regulationPosition
        let newX = (currentPos.x + delta.width / 390).rounded(to: snapUnit)
        let newY = (currentPos.y + delta.height / 844).rounded(to: snapUnit)
        placedItems[idx].adjustedPosition = CGPoint(x: newX, y: newY)
    }

    func resetToPolicy(id: String) {
        guard let idx = placedItems.firstIndex(where: { $0.id == id }) else { return }
        placedItems[idx].adjustedPosition = nil
        placedItems[idx].adjustedRotation = nil
    }

    func updateConfiguration(_ newConfig: UniformConfiguration) {
        configuration = newConfig
        recompute()
    }

    func renderImage(size: CGSize) -> UIImage {
        // Render the canvas to a UIImage for export
        // TODO: Use ImageRenderer for full fidelity rendering
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.systemGray5.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

extension CGFloat {
    func rounded(to snap: CGFloat) -> CGFloat {
        guard snap > 0 else { return self }
        return (self / snap).rounded() * snap
    }
}
