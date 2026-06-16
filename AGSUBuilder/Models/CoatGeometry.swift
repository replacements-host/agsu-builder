import CoreGraphics

/// Normalized coordinate anchors for a single coat silhouette variant.
///
/// All `CGPoint` values are in the range (0,0)→(1,1) relative to the coat image's
/// bounding rectangle. The origin (0,0) is the **top-left** corner.
///
/// **Calibration instructions (do once per variant per real coat image):**
/// 1. Open the coat photograph (≥300 DPI) in an image editor.
/// 2. Measure each anatomical landmark's pixel coordinates (px, py).
/// 3. Set `point.x = px / imageWidth`, `point.y = py / imageHeight`.
/// 4. Set `normalizedUnitsPerInch = (pocketWidthPx / imageWidth) / 4.5`
///    (AGSU pocket is nominally 4.5 inches wide per the uniform specification).
///
/// **All values below are PLACEHOLDER presets** — they are intentionally approximate
/// so the app compiles and renders something without real coat photography.
/// Do not attempt to calibrate these values from the placeholder gray rectangles.
struct CoatGeometry {

    // MARK: - Chest Anchors

    /// Center of the top edge of the left breast pocket.
    /// Ribbon rack bottom edge sits 1/8 inch above this point (DA PAM 670-1, para 22-6c).
    let leftPocketTopCenter: CGPoint

    /// Center of the top edge of the left breast pocket flap.
    /// Anchor for Group 4–5 (marksmanship) badge centering (para 22-15d3).
    let leftPocketFlapTopCenter: CGPoint

    /// Center of the right breast pocket.
    /// CSIB ID badge is centered here (para 22-17).
    let rightPocketCenter: CGPoint

    // MARK: - Lapel Anchors

    /// Lapel center point on wearer's left side.
    /// Officers: branch insignia. Enlisted: branch insignia (US on right).
    let leftLapelCenter: CGPoint

    /// Lapel center point on wearer's right side.
    /// Officers: branch insignia (mirrored). Enlisted: US insignia.
    let rightLapelCenter: CGPoint

    /// X-coordinate of the inner lapel edge on the left side.
    /// Reserved for future collision-detection between lapel insignia and ribbon rack.
    let leftLapelBoundaryX: CGFloat

    // MARK: - Shoulder Anchors

    /// Center of the left shoulder loop (epaulette).
    /// Officer/WO rank insignia; also DUI for enlisted when on dress blues (not AGSU).
    let leftShoulderLoopCenter: CGPoint

    /// Center of the right shoulder loop (epaulette). Mirrors left.
    let rightShoulderLoopCenter: CGPoint

    /// Top of the left shoulder seam. Tab placement reference (para 22-16d).
    let leftShoulderSeamTop: CGPoint

    /// Top of the right shoulder seam. Mirrors left.
    let rightShoulderSeamTop: CGPoint

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

    // MARK: - Collar Anchors

    /// Center of the left collar point. Enlisted grade insignia worn here (para 21-7).
    let leftCollarCenter: CGPoint

    /// Center of the right collar point. Mirrors left.
    let rightCollarCenter: CGPoint

    // MARK: - Scale

    /// Number of normalized units (0–1 range) that equal one physical inch.
    /// Derived from pocket width: `normalizedUnitsPerInch = pocketWidthNorm / 4.5`
    let normalizedUnitsPerInch: CGFloat

    // MARK: - Static Instances

    // NOTE: All anchor values are PLACEHOLDER presets.
    // Replace after measuring real coat photographs at ≥300 DPI.
    // See calibration instructions in the struct-level doc comment above.

    /// Officer male coat (DA PAM 670-1, Fig. 14-1). PLACEHOLDER geometry.
    static let officerMale = CoatGeometry(
        leftPocketTopCenter:            CGPoint(x: 0.42, y: 0.38), // PLACEHOLDER
        leftPocketFlapTopCenter:        CGPoint(x: 0.42, y: 0.42), // PLACEHOLDER
        rightPocketCenter:              CGPoint(x: 0.58, y: 0.44), // PLACEHOLDER
        leftLapelCenter:                CGPoint(x: 0.38, y: 0.28), // PLACEHOLDER
        rightLapelCenter:               CGPoint(x: 0.56, y: 0.28), // PLACEHOLDER
        leftLapelBoundaryX:             0.44,                       // PLACEHOLDER
        leftShoulderLoopCenter:         CGPoint(x: 0.36, y: 0.18), // PLACEHOLDER
        rightShoulderLoopCenter:        CGPoint(x: 0.62, y: 0.18), // PLACEHOLDER
        leftShoulderSeamTop:            CGPoint(x: 0.32, y: 0.16), // PLACEHOLDER
        rightShoulderSeamTop:           CGPoint(x: 0.66, y: 0.16), // PLACEHOLDER
        leftSleeveUpperPatchZone:       CGPoint(x: 0.22, y: 0.25), // PLACEHOLDER
        rightSleeveUpperPatchZone:      CGPoint(x: 0.76, y: 0.25), // PLACEHOLDER
        leftSleeveServiceStripeOrigin:  CGPoint(x: 0.20, y: 0.55), // PLACEHOLDER
        rightSleeveOverseasBarOrigin:   CGPoint(x: 0.78, y: 0.55), // PLACEHOLDER
        leftCollarCenter:               CGPoint(x: 0.40, y: 0.24), // PLACEHOLDER
        rightCollarCenter:              CGPoint(x: 0.58, y: 0.24), // PLACEHOLDER
        normalizedUnitsPerInch:         0.08                        // PLACEHOLDER
    )

    /// Officer female coat (DA PAM 670-1, Fig. 14-2). PLACEHOLDER geometry.
    static let officerFemale = CoatGeometry(
        leftPocketTopCenter:            CGPoint(x: 0.43, y: 0.40), // PLACEHOLDER
        leftPocketFlapTopCenter:        CGPoint(x: 0.43, y: 0.44), // PLACEHOLDER
        rightPocketCenter:              CGPoint(x: 0.57, y: 0.46), // PLACEHOLDER
        leftLapelCenter:                CGPoint(x: 0.39, y: 0.29), // PLACEHOLDER
        rightLapelCenter:               CGPoint(x: 0.55, y: 0.29), // PLACEHOLDER
        leftLapelBoundaryX:             0.45,                       // PLACEHOLDER
        leftShoulderLoopCenter:         CGPoint(x: 0.37, y: 0.19), // PLACEHOLDER
        rightShoulderLoopCenter:        CGPoint(x: 0.61, y: 0.19), // PLACEHOLDER
        leftShoulderSeamTop:            CGPoint(x: 0.33, y: 0.17), // PLACEHOLDER
        rightShoulderSeamTop:           CGPoint(x: 0.65, y: 0.17), // PLACEHOLDER
        leftSleeveUpperPatchZone:       CGPoint(x: 0.23, y: 0.26), // PLACEHOLDER
        rightSleeveUpperPatchZone:      CGPoint(x: 0.75, y: 0.26), // PLACEHOLDER
        leftSleeveServiceStripeOrigin:  CGPoint(x: 0.21, y: 0.56), // PLACEHOLDER
        rightSleeveOverseasBarOrigin:   CGPoint(x: 0.77, y: 0.56), // PLACEHOLDER
        leftCollarCenter:               CGPoint(x: 0.41, y: 0.25), // PLACEHOLDER
        rightCollarCenter:              CGPoint(x: 0.57, y: 0.25), // PLACEHOLDER
        normalizedUnitsPerInch:         0.08                        // PLACEHOLDER
    )

    /// Enlisted male coat (DA PAM 670-1, Fig. 14-3). PLACEHOLDER geometry.
    static let enlistedMale = CoatGeometry(
        leftPocketTopCenter:            CGPoint(x: 0.42, y: 0.39), // PLACEHOLDER
        leftPocketFlapTopCenter:        CGPoint(x: 0.42, y: 0.43), // PLACEHOLDER
        rightPocketCenter:              CGPoint(x: 0.58, y: 0.45), // PLACEHOLDER
        leftLapelCenter:                CGPoint(x: 0.38, y: 0.29), // PLACEHOLDER
        rightLapelCenter:               CGPoint(x: 0.56, y: 0.29), // PLACEHOLDER
        leftLapelBoundaryX:             0.44,                       // PLACEHOLDER
        leftShoulderLoopCenter:         CGPoint(x: 0.36, y: 0.19), // PLACEHOLDER
        rightShoulderLoopCenter:        CGPoint(x: 0.62, y: 0.19), // PLACEHOLDER
        leftShoulderSeamTop:            CGPoint(x: 0.32, y: 0.17), // PLACEHOLDER
        rightShoulderSeamTop:           CGPoint(x: 0.66, y: 0.17), // PLACEHOLDER
        leftSleeveUpperPatchZone:       CGPoint(x: 0.22, y: 0.26), // PLACEHOLDER
        rightSleeveUpperPatchZone:      CGPoint(x: 0.76, y: 0.26), // PLACEHOLDER
        leftSleeveServiceStripeOrigin:  CGPoint(x: 0.20, y: 0.56), // PLACEHOLDER
        rightSleeveOverseasBarOrigin:   CGPoint(x: 0.78, y: 0.56), // PLACEHOLDER
        leftCollarCenter:               CGPoint(x: 0.40, y: 0.25), // PLACEHOLDER
        rightCollarCenter:              CGPoint(x: 0.58, y: 0.25), // PLACEHOLDER
        normalizedUnitsPerInch:         0.08                        // PLACEHOLDER
    )

    /// Enlisted female coat (DA PAM 670-1, Fig. 14-4). PLACEHOLDER geometry.
    static let enlistedFemale = CoatGeometry(
        leftPocketTopCenter:            CGPoint(x: 0.43, y: 0.41), // PLACEHOLDER
        leftPocketFlapTopCenter:        CGPoint(x: 0.43, y: 0.45), // PLACEHOLDER
        rightPocketCenter:              CGPoint(x: 0.57, y: 0.47), // PLACEHOLDER
        leftLapelCenter:                CGPoint(x: 0.39, y: 0.30), // PLACEHOLDER
        rightLapelCenter:               CGPoint(x: 0.55, y: 0.30), // PLACEHOLDER
        leftLapelBoundaryX:             0.45,                       // PLACEHOLDER
        leftShoulderLoopCenter:         CGPoint(x: 0.37, y: 0.20), // PLACEHOLDER
        rightShoulderLoopCenter:        CGPoint(x: 0.61, y: 0.20), // PLACEHOLDER
        leftShoulderSeamTop:            CGPoint(x: 0.33, y: 0.18), // PLACEHOLDER
        rightShoulderSeamTop:           CGPoint(x: 0.65, y: 0.18), // PLACEHOLDER
        leftSleeveUpperPatchZone:       CGPoint(x: 0.23, y: 0.27), // PLACEHOLDER
        rightSleeveUpperPatchZone:      CGPoint(x: 0.75, y: 0.27), // PLACEHOLDER
        leftSleeveServiceStripeOrigin:  CGPoint(x: 0.21, y: 0.57), // PLACEHOLDER
        rightSleeveOverseasBarOrigin:   CGPoint(x: 0.77, y: 0.57), // PLACEHOLDER
        leftCollarCenter:               CGPoint(x: 0.41, y: 0.26), // PLACEHOLDER
        rightCollarCenter:              CGPoint(x: 0.57, y: 0.26), // PLACEHOLDER
        normalizedUnitsPerInch:         0.08                        // PLACEHOLDER
    )
}
