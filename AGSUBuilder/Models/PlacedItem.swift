import SwiftUI

struct PlacedItem: Identifiable {
    let id: String
    let item: UniformItem
    let soldier: Soldier
    let geometry: CoatGeometry
    var regulationPosition: CGPoint
    var regulationRotation: Angle
    var adjustedPosition: CGPoint?
    var adjustedRotation: Angle?
    var renderSize: CGSize
    var measurements: [(label: String, value: String)]
    var regulationRef: String

    var effectivePosition: CGPoint {
        adjustedPosition ?? regulationPosition
    }

    var effectiveRotation: Angle {
        adjustedRotation ?? regulationRotation
    }

    /// True when the user has moved this item beyond the regulation-derived threshold.
    ///
    /// THRESHOLD RATIONALE (DA PAM 670-1, 26 January 2021):
    /// The regulation contains NO numerical tolerance for placement deviation.
    /// - Female soldiers: 1/4" (body-shape adjustment explicitly authorized)
    /// - Male soldiers: 1/8" (precision margin only; no adjustment language)
    /// Items on unconditionallyAdjustable list never trigger this warning.
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
