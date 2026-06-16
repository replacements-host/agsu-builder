import CoreGraphics

/// Normalized coordinate anchors for each coat variant.
/// All CGPoint values are in range (0,0) to (1,1) relative to the coat image bounding rect.
/// Established by manual measurement of DA PAM 670-1 Figures 14-1 through 14-4.
struct CoatGeometry {

    // MARK: - Chest Anchors
    let leftPocketTopCenter: CGPoint      // Ribbon rack: 1/8" above this point (para 22-6)
    let leftPocketFlapTopCenter: CGPoint  // Badge anchor for pocket-flap badges (para 22-15d)
    let rightPocketCenter: CGPoint        // ID badge center (para 22-17)

    // MARK: - Lapel Anchors
    let leftLapelCenter: CGPoint          // Branch insignia (officers); US insignia (enlisted)
    let rightLapelCenter: CGPoint         // US insignia (officers); branch insignia (enlisted)
    let leftLapelBoundaryX: CGFloat       // X position of lapel edge (for collision detection)

    // MARK: - Shoulder Anchors
    let leftShoulderLoopCenter: CGPoint   // DUI (enlisted); rank (officer) (para 21-7, 21-22)
    let rightShoulderLoopCenter: CGPoint
    let leftShoulderSeamTop: CGPoint      // Tab placement reference (para 22-16)
    let rightShoulderSeamTop: CGPoint

    // MARK: - Sleeve Anchors
    let leftSleeveUpperPatchZone: CGPoint   // SSI current organization (para 21-16)
    let rightSleeveUpperPatchZone: CGPoint  // SSI former wartime / combat patch
    let leftSleeveServiceStripeOrigin: CGPoint  // Service stripes (para 21-28)
    let rightSleeveOverseasBarOrigin: CGPoint   // Overseas service bars (para 21-29)

    // MARK: - Collar Anchors (enlisted rank)
    let leftCollarCenter: CGPoint   // Enlisted grade insignia (para 21-7)
    let rightCollarCenter: CGPoint

    // MARK: - Scale
    /// How many normalized units equal one physical inch at this coat's scale
    let normalizedUnitsPerInch: CGFloat

    // MARK: - Static Instances
    // TODO: Calibrate these values by measuring DA PAM figures 14-1 through 14-4
    // at 300 DPI. Each point = pixel_coordinate / image_width or image_height.
    // normalizedUnitsPerInch = (pocket_pixel_width / image_width) / 4.5

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
