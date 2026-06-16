import SwiftUI

/// A `UniformItem` that has been positioned on the coat canvas by `PlacementEngine`.
///
/// `PlacedItem` holds two position layers:
/// - `regulationPosition` — computed from DA PAM 670-1 rules; never mutated after placement.
/// - `adjustedPosition` — optional user override set in Adjust Mode.
///
/// The canvas always renders using `effectivePosition`, which falls back to the
/// regulation position when no adjustment has been made.
struct PlacedItem: Identifiable {

    // MARK: - Identity

    /// Unique string matching `UniformItem.id`.
    let id: String
    /// The source item this placement represents.
    let item: UniformItem

    // MARK: - Context (needed for `isOutOfPolicy`)

    /// Soldier profile at the time of placement — used for the gender-aware threshold.
    let soldier: Soldier
    /// Coat geometry used during placement — provides `normalizedUnitsPerInch`.
    let geometry: CoatGeometry

    // MARK: - Position (normalized 0–1 relative to canvas bounds)

    /// Regulation-derived anchor point. Set once by `PlacementEngine`; never changed.
    var regulationPosition: CGPoint
    /// Regulation-derived rotation (zero for all items in v1).
    var regulationRotation: Angle

    /// User-applied position override from Adjust Mode. `nil` = on policy.
    var adjustedPosition: CGPoint?
    /// User-applied rotation override from Adjust Mode. `nil` = no rotation change.
    var adjustedRotation: Angle?

    // MARK: - Render Metadata

    /// Size in normalized units, derived from the physical dimensions in the regulation.
    var renderSize: CGSize
    /// Human-readable measurement bullets displayed in `RegulationSheetView`.
    var measurements: [(label: String, value: String)]
    /// Citation string shown in the regulation detail sheet.
    var regulationRef: String

    // MARK: - Computed

    /// The position used for rendering: user adjustment if present, otherwise regulation.
    var effectivePosition: CGPoint {
        adjustedPosition ?? regulationPosition
    }

    /// The rotation used for rendering: user adjustment if present, otherwise regulation.
    var effectiveRotation: Angle {
        adjustedRotation ?? regulationRotation
    }

    /// `true` when the user has moved this item beyond the gender-appropriate tolerance.
    ///
    /// **Threshold rationale (DA PAM 670-1, 26 January 2021):**
    /// The regulation does not specify a numerical placement tolerance, so this app uses:
    /// - **Female soldiers — 1/4 inch:** Body-shape adjustment is explicitly authorized.
    /// - **Male soldiers — 1/8 inch:** Precision margin only; no adjustment language exists.
    ///
    /// Items in `unconditionallyAdjustableItems` (DUI on sweater, RDI on sweater) never
    /// trigger this warning because their placement is inherently approximate.
    var isOutOfPolicy: Bool {
        guard let adj = adjustedPosition else { return false }
        let unconditionallyAdjustableItems = ["dui_sweater", "rdi_sweater"]
        if unconditionallyAdjustableItems.contains(item.id) { return false }
        let thresholdInches: CGFloat = soldier.gender == .female ? 0.25 : 0.125
        let threshold = thresholdInches * geometry.normalizedUnitsPerInch
        let distance = hypot(adj.x - regulationPosition.x, adj.y - regulationPosition.y)
        return distance > threshold
    }
}
