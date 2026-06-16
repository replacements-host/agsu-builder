import CoreGraphics

/// Single source of truth for the AGSU coat's shape AND every insignia placement anchor.
///
/// There is no underlying coat image — `CoatLayerView` draws the coat directly from these
/// values, and `PlacementEngine` computes insignia positions from the same values. This
/// guarantees the coat outline and the insignia anchors can never drift out of sync.
///
/// All `CGPoint` and `CGFloat` values are **normalized (0.0 – 1.0)** relative to a logical
/// coat canvas whose aspect ratio is `canvasAspectRatio`. SwiftUI scales this canvas to fit
/// the actual screen size at render time.
///
/// There are **two instances** — `.male` and `.female` — not four. The AGSU coat cut differs
/// by gender (female coat has a fitted waist seam and shallow pocket flaps without functional
/// lower pockets; male coat is straight-cut with four full patch pockets), but does NOT differ
/// between officer and enlisted — the shape is identical. Only insignia placement *rules*
/// differ between officer and enlisted; that logic lives in `PlacementEngine`, not here.
struct CoatGeometry {

    // MARK: - Canvas

    /// Width-to-height ratio of the logical coat drawing canvas.
    /// A standing figure from shoulder to coat hem is taller than wide.
    let canvasAspectRatio: CGFloat

    // MARK: - Chest Anchors

    /// Center of the top edge of the left breast pocket.
    /// Ribbon rack bottom edge sits 1/8 inch above this point (DA PAM 670-1, para 22-6c).
    let leftPocketTopCenter: CGPoint

    /// Center of the top edge of the left breast pocket flap.
    /// Anchor for Group 4–5 (marksmanship) badge centering (para 22-15d3).
    let leftPocketFlapTopCenter: CGPoint

    /// Width and height of the left breast pocket in normalized units — used for drawing.
    let leftPocketSize: CGSize

    /// Center of the right breast pocket.
    /// CSIB ID badge is centered here (para 22-17).
    let rightPocketCenter: CGPoint

    /// Width and height of the right breast pocket in normalized units — used for drawing.
    let rightPocketSize: CGSize

    // MARK: - Lapel Anchors

    /// Lapel center on the wearer's left side.
    /// Officers: branch insignia (para 21-22). Enlisted: branch insignia (para 21-9).
    let leftLapelCenter: CGPoint

    /// Lapel center on the wearer's right side.
    /// Officers: US insignia (para 21-22). Enlisted: US insignia (para 21-9).
    let rightLapelCenter: CGPoint

    /// X-coordinate of the inner lapel edge on the left side.
    /// Reserved for collision-detection between lapel insignia and ribbon rack.
    let leftLapelBoundaryX: CGFloat

    /// Where the collar meets the lapel — used to draw the V-notch.
    let lapelNotchPoint: CGPoint

    /// Top of the collar opening — used to draw the collar.
    let collarTopPoint: CGPoint

    // MARK: - Shoulder Anchors

    /// Center of the left shoulder loop (epaulette).
    /// Officer/WO rank insignia pin-on; DUI for enlisted (para 21-7, 21-22).
    let leftShoulderLoopCenter: CGPoint

    /// Center of the right shoulder loop. Mirrors left.
    let rightShoulderLoopCenter: CGPoint

    /// Top of the left shoulder seam. Tab placement reference (para 22-16d).
    let leftShoulderSeamTop: CGPoint

    /// Top of the right shoulder seam. Mirrors left.
    let rightShoulderSeamTop: CGPoint

    /// Outer shoulder-to-shoulder span in normalized units — used to draw the silhouette.
    let shoulderWidth: CGFloat

    // MARK: - Sleeve Anchors

    /// Upper-left sleeve SSI zone (current unit patch — para 21-16).
    let leftSleeveUpperPatchZone: CGPoint

    /// Upper-right sleeve SSI zone (former wartime / combat patch).
    let rightSleeveUpperPatchZone: CGPoint

    /// Origin for the bottom-most service stripe on the left sleeve (para 21-28).
    /// Stripes stack upward from this point at 1/4-inch intervals.
    let leftSleeveServiceStripeOrigin: CGPoint

    /// Origin for the bottom-most overseas bar on the right sleeve (para 21-29).
    let rightSleeveOverseasBarOrigin: CGPoint

    /// Outer edge of the sleeve at chest height — used to draw the silhouette.
    let sleeveOuterEdgeX: CGFloat

    /// Y-coordinate of the bottom edge of the sleeve (cuff line) — used for drawing.
    let cuffY: CGFloat

    // MARK: - Collar Anchors (enlisted rank)

    /// Center of the left collar point. Enlisted grade insignia worn here (para 21-7).
    let leftCollarCenter: CGPoint

    /// Center of the right collar point. Mirrors left.
    let rightCollarCenter: CGPoint

    // MARK: - Body Silhouette (drawing only — not insignia anchors)

    /// Y-coordinate of the belt line.
    let waistY: CGFloat

    /// Y-coordinate of the bottom edge of the coat (hem).
    let hemY: CGFloat

    /// Height of the belt strip in normalized units.
    let beltHeight: CGFloat

    /// `true` for the female cut — `CoatLayerView` draws a horizontal seam line at `waistY`.
    let hasFittedWaistSeam: Bool

    /// `false` for the female cut — lower pockets are flap-only per DA PAM; no pocket body drawn.
    let hasFunctionalHipPockets: Bool

    // MARK: - Scale

    /// Number of normalized units (0–1 range) equal to one physical inch.
    ///
    /// Since the coat is drawn — not photographed — this is set by design:
    ///   - Male reference coat height ≈ 30 inches → 1/30 ≈ 0.033
    ///   - Female reference coat is slightly shorter → 0.035
    ///
    /// Used by `PlacementEngine` for measurement math (ribbon rack height, badge offsets)
    /// and by `PlacedItem.isOutOfPolicy` for the out-of-policy threshold calculation.
    let normalizedUnitsPerInch: CGFloat

    // MARK: - Static Instances

    /// Male coat cut. Used by both `.officerMale` and `.enlistedMale` `CoatVariant` cases.
    ///
    /// Straight-cut silhouette with four full patch pockets.
    /// All values are deliberate design choices about the coat's proportions, not
    /// calibration measurements of an external image — they can be adjusted for visual
    /// polish by changing a single constant; no separate calibration step is required.
    static let male = CoatGeometry(
        canvasAspectRatio:             0.62,
        leftPocketTopCenter:           CGPoint(x: 0.40, y: 0.38),
        leftPocketFlapTopCenter:       CGPoint(x: 0.40, y: 0.40),
        leftPocketSize:                CGSize(width: 0.14, height: 0.11),
        rightPocketCenter:             CGPoint(x: 0.62, y: 0.40),
        rightPocketSize:               CGSize(width: 0.14, height: 0.11),
        leftLapelCenter:               CGPoint(x: 0.37, y: 0.20),
        rightLapelCenter:              CGPoint(x: 0.63, y: 0.20),
        leftLapelBoundaryX:            0.46,
        lapelNotchPoint:               CGPoint(x: 0.50, y: 0.23),
        collarTopPoint:                CGPoint(x: 0.50, y: 0.10),
        leftShoulderLoopCenter:        CGPoint(x: 0.32, y: 0.09),
        rightShoulderLoopCenter:       CGPoint(x: 0.68, y: 0.09),
        leftShoulderSeamTop:           CGPoint(x: 0.27, y: 0.08),
        rightShoulderSeamTop:          CGPoint(x: 0.73, y: 0.08),
        shoulderWidth:                 0.62,
        leftSleeveUpperPatchZone:      CGPoint(x: 0.20, y: 0.18),
        rightSleeveUpperPatchZone:     CGPoint(x: 0.80, y: 0.18),
        leftSleeveServiceStripeOrigin: CGPoint(x: 0.18, y: 0.52),
        rightSleeveOverseasBarOrigin:  CGPoint(x: 0.82, y: 0.52),
        sleeveOuterEdgeX:              0.16,
        cuffY:                         0.66,
        leftCollarCenter:              CGPoint(x: 0.42, y: 0.13),
        rightCollarCenter:             CGPoint(x: 0.58, y: 0.13),
        waistY:                        0.48,
        hemY:                          0.74,
        beltHeight:                    0.02,
        hasFittedWaistSeam:            false,
        hasFunctionalHipPockets:       true,
        normalizedUnitsPerInch:        0.033  // 1.0 canvas height ≈ 30" coat length → 1/30 ≈ 0.033
    )

    /// Female coat cut. Used by both `.officerFemale` and `.enlistedFemale` `CoatVariant` cases.
    ///
    /// Fitted silhouette with waist seam and shallow pocket flaps (no functional lower pockets)
    /// per DA PAM 670-1, para 14-4.
    static let female = CoatGeometry(
        canvasAspectRatio:             0.58,
        leftPocketTopCenter:           CGPoint(x: 0.40, y: 0.36),
        leftPocketFlapTopCenter:       CGPoint(x: 0.40, y: 0.38),
        leftPocketSize:                CGSize(width: 0.13, height: 0.04),  // flap only — shallow
        rightPocketCenter:             CGPoint(x: 0.62, y: 0.38),
        rightPocketSize:               CGSize(width: 0.13, height: 0.04),
        leftLapelCenter:               CGPoint(x: 0.38, y: 0.19),
        rightLapelCenter:              CGPoint(x: 0.62, y: 0.19),
        leftLapelBoundaryX:            0.47,
        lapelNotchPoint:               CGPoint(x: 0.50, y: 0.22),
        collarTopPoint:                CGPoint(x: 0.50, y: 0.09),
        leftShoulderLoopCenter:        CGPoint(x: 0.33, y: 0.085),
        rightShoulderLoopCenter:       CGPoint(x: 0.67, y: 0.085),
        leftShoulderSeamTop:           CGPoint(x: 0.29, y: 0.075),
        rightShoulderSeamTop:          CGPoint(x: 0.71, y: 0.075),
        shoulderWidth:                 0.58,
        leftSleeveUpperPatchZone:      CGPoint(x: 0.22, y: 0.17),
        rightSleeveUpperPatchZone:     CGPoint(x: 0.78, y: 0.17),
        leftSleeveServiceStripeOrigin: CGPoint(x: 0.20, y: 0.50),
        rightSleeveOverseasBarOrigin:  CGPoint(x: 0.80, y: 0.50),
        sleeveOuterEdgeX:              0.18,
        cuffY:                         0.64,
        leftCollarCenter:              CGPoint(x: 0.42, y: 0.125),
        rightCollarCenter:             CGPoint(x: 0.58, y: 0.125),
        waistY:                        0.43,
        hemY:                          0.70,
        beltHeight:                    0.018,
        hasFittedWaistSeam:            true,
        hasFunctionalHipPockets:       false,
        normalizedUnitsPerInch:        0.035  // slightly shorter reference coat length
    )
}
