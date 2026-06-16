import SwiftUI

/// Draws the AGSU coat silhouette as native SwiftUI vector shapes.
///
/// There is no coat image asset. The coat is rendered entirely from the normalized
/// anchor points and silhouette dimensions stored in `CoatGeometry`. This guarantees
/// the drawn coat outline and the insignia placement anchors used by `PlacementEngine`
/// are always in sync — they are the same values, used twice.
///
/// **Coordinate system:** all drawing helpers multiply normalized (0–1) geometry
/// values by `w` (view width) and `h` (view height) to produce SwiftUI points —
/// the same arithmetic that `InsigniaLayerView` uses for placed items. Both views
/// must be given the same physical frame for insignia to land on the correct coat feature.
///
/// **Style:** light gray fill (`Color(.systemGray6)`) with a `Color.primary` stroke —
/// a clean technical illustration, not a photorealistic rendering. Adapts automatically
/// to light and dark mode via semantic colors.
struct CoatLayerView: View {

    /// The coat geometry to draw. Must be the same instance used by `PlacementEngine`
    /// (obtained via `soldier.coatVariant.geometry`).
    let geometry: CoatGeometry

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                // Body silhouette — closed path: shoulders → sleeves → hem → up the center
                silhouettePath(w: w, h: h)
                    .fill(Color(.systemGray6))
                silhouettePath(w: w, h: h)
                    .stroke(Color.primary, lineWidth: 1.5)

                // Lapels — angled lines from shoulder break to lapel notch
                lapelPath(w: w, h: h, left: true)
                    .stroke(Color.primary, lineWidth: 1.0)
                lapelPath(w: w, h: h, left: false)
                    .stroke(Color.primary, lineWidth: 1.0)

                // Breast pockets (left and right)
                pocketRect(center: geometry.leftPocketTopCenter,
                           size:   geometry.leftPocketSize,
                           w: w, h: h)
                    .stroke(Color.primary, lineWidth: 0.75)

                pocketRect(center: geometry.rightPocketCenter,
                           size:   geometry.rightPocketSize,
                           w: w, h: h)
                    .stroke(Color.primary, lineWidth: 0.75)

                // Belt strip across the waist
                Rectangle()
                    .stroke(Color.primary, lineWidth: 0.75)
                    .frame(width: w * 0.70, height: h * geometry.beltHeight)
                    .position(x: w * 0.50, y: h * geometry.waistY)

                // Waist seam line (female cut only — DA PAM 670-1, para 14-4)
                if geometry.hasFittedWaistSeam {
                    waistSeamPath(w: w, h: h)
                        .stroke(Color.primary, lineWidth: 0.5)
                }

                // Shoulder loops (epaulettes) — left and right
                shoulderLoopShape(center: geometry.leftShoulderLoopCenter,  w: w, h: h)
                    .stroke(Color.primary, lineWidth: 0.75)
                shoulderLoopShape(center: geometry.rightShoulderLoopCenter, w: w, h: h)
                    .stroke(Color.primary, lineWidth: 0.75)
            }
        }
        .aspectRatio(geometry.canvasAspectRatio, contentMode: .fit)
    }

    // MARK: - Drawing Helpers

    /// Closed body silhouette: top of left shoulder → left sleeve outer edge → left cuff →
    /// across hem → right cuff → right sleeve → right shoulder → V-neck → back to start.
    private func silhouettePath(w: CGFloat, h: CGFloat) -> Path {
        let halfShoulder = geometry.shoulderWidth / 2
        let leftShoulderX  = (0.50 - halfShoulder / 2) * w
        let rightShoulderX = (0.50 + halfShoulder / 2) * w
        let shoulderY      = geometry.leftShoulderSeamTop.y * h
        let leftSleeveX    = geometry.sleeveOuterEdgeX * w
        let rightSleeveX   = (1.0 - geometry.sleeveOuterEdgeX) * w
        let cuffY          = geometry.cuffY * h
        let hemY           = geometry.hemY * h
        let notchX         = geometry.lapelNotchPoint.x * w
        let notchY         = geometry.lapelNotchPoint.y * h
        let collarY        = geometry.collarTopPoint.y * h

        return Path { p in
            // Top-left shoulder
            p.move(to: CGPoint(x: leftShoulderX, y: shoulderY))
            // Down left sleeve outer edge
            p.addLine(to: CGPoint(x: leftSleeveX,  y: shoulderY))
            p.addLine(to: CGPoint(x: leftSleeveX,  y: cuffY))
            // Across the hem
            p.addLine(to: CGPoint(x: rightSleeveX, y: cuffY))
            // Up right sleeve
            p.addLine(to: CGPoint(x: rightSleeveX, y: shoulderY))
            // Top-right shoulder
            p.addLine(to: CGPoint(x: rightShoulderX, y: shoulderY))
            // Down right lapel to notch
            p.addLine(to: CGPoint(x: notchX + 2, y: notchY))
            // Collar arc across the top
            p.addQuadCurve(
                to:      CGPoint(x: notchX - 2, y: notchY),
                control: CGPoint(x: notchX, y: collarY)
            )
            // Back up left lapel to shoulder
            p.addLine(to: CGPoint(x: leftShoulderX, y: shoulderY))
            p.closeSubpath()

            // Hem bottom edge (drawn as a separate horizontal line for clarity)
            p.move(to: CGPoint(x: leftSleeveX,  y: hemY))
            p.addLine(to: CGPoint(x: rightSleeveX, y: hemY))
        }
    }

    /// Single lapel line from shoulder break to the V-notch.
    private func lapelPath(w: CGFloat, h: CGFloat, left: Bool) -> Path {
        let lapelCenter = left ? geometry.leftLapelCenter : geometry.rightLapelCenter
        let notch       = geometry.lapelNotchPoint
        let halfShoulder = geometry.shoulderWidth / 2
        let shoulderX: CGFloat = left
            ? (0.50 - halfShoulder / 2) * w
            : (0.50 + halfShoulder / 2) * w

        return Path { p in
            p.move(to: CGPoint(x: shoulderX, y: geometry.leftShoulderSeamTop.y * h))
            p.addLine(to: CGPoint(x: lapelCenter.x * w, y: lapelCenter.y * h))
            p.addLine(to: CGPoint(x: notch.x * w,       y: notch.y * h))
        }
    }

    /// Pocket rectangle. `center` is the top-center for breast pockets.
    private func pocketRect(center: CGPoint, size: CGSize, w: CGFloat, h: CGFloat) -> Path {
        let cx = center.x * w
        let cy = center.y * h
        let pw = size.width  * w
        let ph = size.height * h
        let rect = CGRect(x: cx - pw / 2, y: cy, width: pw, height: ph)
        return Path(rect)
    }

    /// Horizontal seam line across the coat at `waistY` — female cut only.
    private func waistSeamPath(w: CGFloat, h: CGFloat) -> Path {
        let leftEdgeX  = geometry.sleeveOuterEdgeX * w
        let rightEdgeX = (1.0 - geometry.sleeveOuterEdgeX) * w
        let y          = geometry.waistY * h
        return Path { p in
            p.move(to:    CGPoint(x: leftEdgeX,  y: y))
            p.addLine(to: CGPoint(x: rightEdgeX, y: y))
        }
    }

    /// Small rounded rectangle representing a shoulder loop (epaulette).
    private func shoulderLoopShape(center: CGPoint, w: CGFloat, h: CGFloat) -> Path {
        let cx  = center.x * w
        let cy  = center.y * h
        let lw  = w * 0.095  // loop width ≈ 9.5% of canvas width
        let lh  = h * 0.038  // loop height ≈ 3.8% of canvas height
        let rect = CGRect(x: cx - lw / 2, y: cy - lh / 2, width: lw, height: lh)
        return Path(roundedRect: rect, cornerRadius: 3)
    }
}

#Preview {
    VStack(spacing: 20) {
        CoatLayerView(geometry: .male)
            .frame(width: 240, height: 240 / 0.62)
            .border(Color.red.opacity(0.3))

        CoatLayerView(geometry: .female)
            .frame(width: 220, height: 220 / 0.58)
            .border(Color.blue.opacity(0.3))
    }
    .padding()
}
