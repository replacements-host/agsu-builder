import SwiftUI
import Combine

/// Canvas zoom presets that animate to specific areas of the coat.
/// Each case maps to a fixed `zoomScale` and `zoomOffset` in `CanvasViewModel.zoomTo(_:)`.
enum ZoomZone: String, CaseIterable {
    case full       = "Full"
    case leftChest  = "Left Chest"
    case rightChest = "Right Chest"
    case sleeves    = "Sleeves"
}

/// Drives the interactive coat canvas (rendered by `CanvasView`).
///
/// Responsibilities:
/// - Runs `PlacementEngine` to compute `PlacedItem` positions whenever the
///   soldier profile, item list, or configuration changes.
/// - Tracks which placed item the user has tapped (for `RegulationSheetView`).
/// - Manages zoom state (preset zones + pinch gesture).
/// - Applies user position adjustments from Adjust Mode.
/// - Renders the canvas to a `UIImage` for the export flow.
@MainActor
class CanvasViewModel: ObservableObject {

    // MARK: - Published State

    @Published var soldier:           Soldier
    @Published var selectedItems:     [UniformItem]
    @Published var configuration:     UniformConfiguration
    /// Output of the last `PlacementEngine.place()` call.
    @Published var placedItems:       [PlacedItem] = []
    /// The tapped item; drives `RegulationSheetView` presentation.
    @Published var selectedPlacedItem: PlacedItem? = nil
    /// Currently active zoom preset.
    @Published var zoomZone:          ZoomZone = .full
    @Published var zoomScale:         CGFloat  = 1.0
    @Published var zoomOffset:        CGSize   = .zero

    // MARK: - Private

    /// Lazily constructs a `PlacementEngine` from the current soldier + configuration.
    private var engine: PlacementEngine {
        PlacementEngine(geometry: soldier.coatVariant.geometry, config: configuration)
    }

    // MARK: - Init

    init(soldier: Soldier, items: [UniformItem] = [], config: UniformConfiguration = UniformConfiguration()) {
        self.soldier       = soldier
        self.selectedItems = items
        self.configuration = config
        recompute()
    }

    // MARK: - Placement

    /// Re-runs the placement engine with the current soldier + items + configuration.
    /// Call whenever any of those three inputs changes.
    func recompute() {
        placedItems = engine.place(items: selectedItems, soldier: soldier)
    }

    // MARK: - Zoom

    /// Animates the canvas to a preset zoom zone.
    /// Offset values are in SwiftUI points relative to the canvas center.
    func zoomTo(_ zone: ZoomZone) {
        withAnimation(.easeInOut(duration: 0.35)) {
            zoomZone = zone
            switch zone {
            case .full:
                zoomScale  = 1.0
                zoomOffset = .zero
            case .leftChest:
                zoomScale  = 2.2
                zoomOffset = CGSize(width: 60, height: -40)
            case .rightChest:
                zoomScale  = 2.2
                zoomOffset = CGSize(width: -60, height: -40)
            case .sleeves:
                zoomScale  = 1.5
                zoomOffset = CGSize(width: 0, height: -70)
            }
        }
    }

    // MARK: - Tap / Selection

    /// Converts a tap point (in canvas-local points) to normalized coordinates,
    /// then selects the nearest `PlacedItem` within a fixed tolerance radius.
    ///
    /// - Parameters:
    ///   - point: Tap location in the coordinate space of the canvas `GeometryReader`.
    ///   - canvasSize: Full size of the canvas frame.
    func handleTap(at point: CGPoint, in canvasSize: CGSize) {
        let normalized = CGPoint(
            x: point.x / canvasSize.width,
            y: point.y / canvasSize.height
        )
        let tolerance: CGFloat = 0.05  // ~5% of canvas width (~20 pt on a 390-pt canvas)
        let nearest = placedItems.min { a, b in
            let da = hypot(a.effectivePosition.x - normalized.x, a.effectivePosition.y - normalized.y)
            let db = hypot(b.effectivePosition.x - normalized.x, b.effectivePosition.y - normalized.y)
            return da < db
        }
        guard let item = nearest else { return }
        let dist = hypot(item.effectivePosition.x - normalized.x, item.effectivePosition.y - normalized.y)
        selectedPlacedItem = dist < tolerance ? item : nil
    }

    // MARK: - Adjust Mode

    /// Moves a placed item by `delta` points (in SwiftUI screen space), snapping to
    /// the nearest `snapInches` increment in normalized coat coordinates.
    ///
    /// - Parameters:
    ///   - id: The `PlacedItem.id` to move.
    ///   - delta: Screen-space translation in points.
    ///   - snapInches: Snap grid increment (e.g. 0.0625 for 1/16 inch).
    func moveItem(id: String, by delta: CGSize, snapInches: CGFloat) {
        guard let idx = placedItems.firstIndex(where: { $0.id == id }) else { return }
        let snapUnit   = snapInches * soldier.coatVariant.geometry.normalizedUnitsPerInch
        let currentPos = placedItems[idx].adjustedPosition ?? placedItems[idx].regulationPosition
        // delta is a unit direction vector (±1, 0) — move exactly one snap increment
        let newX = max(0, min(1, currentPos.x + delta.width  * snapUnit))
        let newY = max(0, min(1, currentPos.y + delta.height * snapUnit))
        placedItems[idx].adjustedPosition = CGPoint(x: newX, y: newY)
    }

    /// Clears any position or rotation override for the given item,
    /// returning it to its regulation-derived position.
    func resetToPolicy(id: String) {
        guard let idx = placedItems.firstIndex(where: { $0.id == id }) else { return }
        placedItems[idx].adjustedPosition = nil
        placedItems[idx].adjustedRotation = nil
    }

    /// Applies a new ribbon rack configuration and immediately recomputes placement.
    func updateConfiguration(_ newConfig: UniformConfiguration) {
        configuration = newConfig
        recompute()
    }

    // MARK: - Export

    /// Renders the canvas to a `UIImage` at the given point size.
    /// Currently produces a solid gray rectangle; wire up `ImageRenderer` for full fidelity.
    func renderImage(size: CGSize) -> UIImage {
        // TODO: Replace with SwiftUI ImageRenderer wrapping CoatLayerView + InsigniaLayerView
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.systemGray5.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - CGFloat Snap Helper

extension CGFloat {
    /// Rounds `self` to the nearest multiple of `snap`.
    /// Returns `self` unchanged when `snap` is zero (avoids divide-by-zero).
    func rounded(to snap: CGFloat) -> CGFloat {
        guard snap > 0 else { return self }
        return (self / snap).rounded() * snap
    }
}
