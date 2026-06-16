import CoreGraphics
import SwiftUI

/// User-configurable regulation options that affect placement computation.
struct UniformConfiguration {
    var ribbonsPerRow: Int = 3          // 3 or 4 (DA PAM 670-1, para 22-6)
    var ribbonRowSpacing: String = "none"       // "none" or "eighth_inch"
    var ribbonTopRowAlignment: String = "centered"  // "centered" or "left"
    var badgeGroupThreePosition: String = "above"   // "above" or "below" ribbon rack
}

/// PlacementEngine converts a Soldier profile + array of UniformItems
/// into an array of PlacedItems with regulation-correct positions.
/// All placement logic is traceable to DA PAM 670-1, 26 January 2021.
///
/// Resolution order (items placed in this sequence because
/// later items depend on the computed geometry of earlier ones):
/// 1. Ribbon rack
/// 2. Group 1-2 badges (position depends on ribbon rack height)
/// 3. Group 3 badges (position depends on Groups 1-2)
/// 4. Group 4 & 5 badges (pocket flap)
/// 5. ID badges (independent — right pocket)
/// 6. Rank insignia
/// 7. Branch / US insignia
/// 8. Tabs
/// 9. Service stripes and overseas bars
struct PlacementEngine {

    let geometry: CoatGeometry
    let config: UniformConfiguration

    // MARK: - Ribbon Rack Result

    struct RibbonRackResult {
        let placedItems: [PlacedItem]
        let rackTopY: CGFloat
        let rackBottomY: CGFloat
        let rackCenterX: CGFloat
    }

    // MARK: - Primary Entry Point

    func place(items: [UniformItem], soldier: Soldier) -> [PlacedItem] {
        var placed: [PlacedItem] = []

        let ribbons  = items.filter { $0.category == .ribbon }
        let group1_2 = items.filter { if case .badge(let g) = $0.category { return g <= 2 } else { return false } }
        let group3   = items.filter { if case .badge(let g) = $0.category { return g == 3 } else { return false } }
        let group4   = items.filter { if case .badge(let g) = $0.category { return g == 4 } else { return false } }
        let group5   = items.filter { if case .badge(let g) = $0.category { return g == 5 } else { return false } }
        let idBadges = items.filter { if case .idBadge = $0.category { return true } else { return false } }
        let tabs     = items.filter { if case .tab = $0.category { return true } else { return false } }

        // Step 1: Ribbon rack
        // DA PAM 670-1, para 22-6(c): ribbons centered 1/8" above left breast pocket on AGSU
        let ribbonPlacement = placeRibbonRack(ribbons: ribbons, soldier: soldier)
        placed.append(contentsOf: ribbonPlacement.placedItems)

        // Step 2: Group 1 and 2 badges
        // DA PAM 670-1, para 22-16: placed above ribbon rack in group precedence order
        let g1g2Placement = placeGroup1And2Badges(
            badges: group1_2, soldier: soldier,
            ribbonRackTop: ribbonPlacement.rackTopY,
            ribbonRackCenterX: ribbonPlacement.rackCenterX
        )
        placed.append(contentsOf: g1g2Placement)

        // Step 3: Group 3 badge
        // DA PAM 670-1, para 22-16: authorized above OR below ribbons.
        // Default: above (corrects iUniform documented bug of forcing below)
        let g3Placement = placeGroup3Badge(
            badges: group3, soldier: soldier,
            ribbonRackTop: ribbonPlacement.rackTopY,
            ribbonRackBottom: ribbonPlacement.rackBottomY,
            group1_2TopY: g1g2Placement.first?.regulationPosition.y,
            position: config.badgeGroupThreePosition
        )
        placed.append(contentsOf: g3Placement)

        // Step 4: Group 4 and 5 badges (pocket flap)
        // DA PAM 670-1, para 22-15d(3): AGSU marksmanship badges on left breast pocket flap
        let g4g5Placement = placeGroup4And5Badges(
            group4Badges: group4, group5Badges: group5, soldier: soldier
        )
        placed.append(contentsOf: g4g5Placement)

        // Step 5: ID badges
        // DA PAM 670-1, para 22-17: centered on pocket, one per side max
        let idPlacement = placeIDBadges(idBadges: idBadges, soldier: soldier)
        placed.append(contentsOf: idPlacement)

        // Step 6: Rank insignia
        // DA PAM 670-1, para 21-5 through 21-8
        let rankPlacement = placeRankInsignia(soldier: soldier)
        placed.append(contentsOf: rankPlacement)

        // Step 7: Branch and US insignia
        // DA PAM 670-1, para 21-4, 21-9 through 21-13
        let insigniaPlacement = placeBranchAndUSInsignia(soldier: soldier)
        placed.append(contentsOf: insigniaPlacement)

        // Step 8: Tabs
        // DA PAM 670-1, para 22-16d: nonsubdued tabs sewn on coat, above SSI zone
        let tabPlacement = placeTabs(tabs: tabs, soldier: soldier)
        placed.append(contentsOf: tabPlacement)

        // Step 9: Service stripes and overseas bars
        // DA PAM 670-1, para 21-28, 21-29
        let sleeveItems = placeSleeveItems(items: items, soldier: soldier)
        placed.append(contentsOf: sleeveItems)

        return placed
    }

    // MARK: - Ribbon Rack Placement

    private func placeRibbonRack(ribbons: [UniformItem], soldier: Soldier) -> RibbonRackResult {
        // DA PAM 670-1, para 22-6(c):
        // "On the AGSU coat, Soldiers wear the ribbons centered 1/8 inch above the left breast pocket."
        guard !ribbons.isEmpty else {
            return RibbonRackResult(
                placedItems: [],
                rackTopY: geometry.leftPocketTopCenter.y,
                rackBottomY: geometry.leftPocketTopCenter.y,
                rackCenterX: geometry.leftPocketTopCenter.x
            )
        }

        let sorted = ribbons.sorted { lookupPrecedence($0) < lookupPrecedence($1) }

        let perRow = config.ribbonsPerRow
        let rowCount = Int(ceil(Double(sorted.count) / Double(perRow)))

        let ribbonWidth  = 1.375 * geometry.normalizedUnitsPerInch  // 1-3/8 inches wide
        let ribbonHeight = 0.375 * geometry.normalizedUnitsPerInch  // 3/8 inch high
        let rowSpacingPts: CGFloat = config.ribbonRowSpacing == "eighth_inch"
            ? 0.125 * geometry.normalizedUnitsPerInch
            : 0

        let rackHeight  = (CGFloat(rowCount) * ribbonHeight) + (CGFloat(rowCount - 1) * rowSpacingPts)
        let rackWidth   = CGFloat(perRow) * ribbonWidth
        let offsetAbovePocket = 0.125 * geometry.normalizedUnitsPerInch
        let rackBottomY = geometry.leftPocketTopCenter.y - offsetAbovePocket
        let rackTopY    = rackBottomY - rackHeight
        let rackCenterX = geometry.leftPocketTopCenter.x

        var placedRibbons: [PlacedItem] = []
        for (index, ribbon) in sorted.enumerated() {
            let row = index / perRow   // 0 = bottom row
            let col = index % perRow   // 0 = wearer's right (viewer's left)

            let ribbonX = rackCenterX - (rackWidth / 2) + (CGFloat(col) * ribbonWidth) + (ribbonWidth / 2)
            let ribbonY = rackBottomY - (CGFloat(row) * (ribbonHeight + rowSpacingPts)) - (ribbonHeight / 2)

            let isTopRow = row == rowCount - 1
            let topRowRibbonCount = sorted.count - (row * perRow)
            var adjustedX = ribbonX
            if isTopRow && topRowRibbonCount < perRow {
                if config.ribbonTopRowAlignment == "centered" {
                    let topRowWidth  = CGFloat(topRowRibbonCount) * ribbonWidth
                    let topRowStartX = rackCenterX - (topRowWidth / 2)
                    adjustedX = topRowStartX + (CGFloat(col) * ribbonWidth) + (ribbonWidth / 2)
                }
            }

            let placed = PlacedItem(
                id: ribbon.id,
                item: ribbon,
                soldier: soldier,
                geometry: geometry,
                regulationPosition: CGPoint(x: adjustedX, y: ribbonY),
                regulationRotation: .zero,
                adjustedPosition: nil,
                adjustedRotation: nil,
                renderSize: CGSize(width: ribbonWidth, height: ribbonHeight),
                measurements: [
                    ("Position", "1/8\" above left breast pocket"),
                    ("Rows", "\(rowCount) row(s) of \(perRow)")
                ],
                regulationRef: "DA PAM 670-1, para 22-6(c)"
            )
            placedRibbons.append(placed)
        }

        return RibbonRackResult(
            placedItems: placedRibbons,
            rackTopY: rackTopY,
            rackBottomY: rackBottomY,
            rackCenterX: rackCenterX
        )
    }

    // MARK: - Group 1 & 2 Badge Placement

    private func placeGroup1And2Badges(
        badges: [UniformItem], soldier: Soldier,
        ribbonRackTop: CGFloat, ribbonRackCenterX: CGFloat
    ) -> [PlacedItem] {
        // DA PAM 670-1, para 22-16:
        // Group 1 and Group 2 badges worn above ribbons in group precedence order.
        // When both groups present, they stack vertically; higher group precedence worn higher.
        guard !badges.isEmpty else { return [] }

        let badgeHeight     = 1.0 * geometry.normalizedUnitsPerInch
        let spacingBetween  = 0.25 * geometry.normalizedUnitsPerInch

        var placed: [PlacedItem] = []
        let sortedByGroup = badges.sorted { groupOf($0) < groupOf($1) }
        var currentBottomY = ribbonRackTop - (0.125 * geometry.normalizedUnitsPerInch)

        for badge in sortedByGroup {
            let badgeY = currentBottomY - (badgeHeight / 2)
            placed.append(PlacedItem(
                id: badge.id,
                item: badge,
                soldier: soldier,
                geometry: geometry,
                regulationPosition: CGPoint(x: ribbonRackCenterX, y: badgeY),
                regulationRotation: .zero,
                adjustedPosition: nil,
                adjustedRotation: nil,
                renderSize: CGSize(width: 2.0 * geometry.normalizedUnitsPerInch, height: badgeHeight),
                measurements: [
                    ("Position", "Above ribbon rack"),
                    ("Spacing", "1/4\" min between badges")
                ],
                regulationRef: "DA PAM 670-1, para 22-16"
            ))
            currentBottomY = badgeY - (badgeHeight / 2) - spacingBetween
        }

        return placed
    }

    // MARK: - Group 3 Badge Placement

    private func placeGroup3Badge(
        badges: [UniformItem], soldier: Soldier,
        ribbonRackTop: CGFloat, ribbonRackBottom: CGFloat,
        group1_2TopY: CGFloat?,
        position: String
    ) -> [PlacedItem] {
        // DA PAM 670-1, para 22-16:
        // Group 3 badges may be worn above the ribbon rack (with Groups 1/2)
        // OR below the ribbon rack. Both are authorized.
        // Default: ABOVE (corrects iUniform bug; iUniform forced below)
        guard let badge = badges.first else { return [] }

        let badgeHeight = 1.0 * geometry.normalizedUnitsPerInch
        let spacing     = 0.25 * geometry.normalizedUnitsPerInch

        let badgeY: CGFloat
        if position == "above" {
            let anchorY = group1_2TopY ?? ribbonRackTop
            badgeY = anchorY - spacing - (badgeHeight / 2)
        } else {
            badgeY = ribbonRackBottom + spacing + (badgeHeight / 2)
        }

        return [PlacedItem(
            id: badge.id,
            item: badge,
            soldier: soldier,
            geometry: geometry,
            regulationPosition: CGPoint(x: geometry.leftPocketTopCenter.x, y: badgeY),
            regulationRotation: .zero,
            adjustedPosition: nil,
            adjustedRotation: nil,
            renderSize: CGSize(width: 2.5 * geometry.normalizedUnitsPerInch, height: badgeHeight),
            measurements: [
                ("Position", position == "above" ? "Above ribbon rack" : "Below ribbon rack")
            ],
            regulationRef: "DA PAM 670-1, para 22-16"
        )]
    }

    // MARK: - Pocket Flap Badges (Groups 4 & 5)

    private func placeGroup4And5Badges(
        group4Badges: [UniformItem], group5Badges: [UniformItem], soldier: Soldier
    ) -> [PlacedItem] {
        // DA PAM 670-1, para 22-15d(3) (AGSU):
        // "Marksmanship badges are worn on the left breast pocket flap..."
        // "upper portion of the badge approximately 1/8 inch below the top of the pocket."
        // TODO: Implement full Group 4 and 5 badge placement logic
        // For v1, place up to 3 badges evenly spaced on left pocket flap
        return []
    }

    // MARK: - ID Badge Placement

    private func placeIDBadges(idBadges: [UniformItem], soldier: Soldier) -> [PlacedItem] {
        // DA PAM 670-1, para 22-17:
        // "Only one badge may be worn on each pocket."
        // CSIB goes on RIGHT pocket. All other ID badges go on LEFT pocket.
        var placed: [PlacedItem] = []

        for badge in idBadges.prefix(2) {
            let isCSIB = badge.id == "combat_service_id_badge"
            let anchorPoint = isCSIB
                ? geometry.rightPocketCenter
                : CGPoint(x: geometry.leftPocketFlapTopCenter.x, y: geometry.leftPocketFlapTopCenter.y + 0.04)

            placed.append(PlacedItem(
                id: badge.id,
                item: badge,
                soldier: soldier,
                geometry: geometry,
                regulationPosition: anchorPoint,
                regulationRotation: .zero,
                adjustedPosition: nil,
                adjustedRotation: nil,
                renderSize: CGSize(
                    width:  1.5 * geometry.normalizedUnitsPerInch,
                    height: 1.5 * geometry.normalizedUnitsPerInch
                ),
                measurements: [
                    ("Position", isCSIB ? "Right breast pocket, centered" : "Left breast pocket, centered")
                ],
                regulationRef: "DA PAM 670-1, para 22-17"
            ))
        }

        return placed
    }

    // MARK: - Rank Insignia

    private func placeRankInsignia(soldier: Soldier) -> [PlacedItem] {
        // DA PAM 670-1, para 21-5 through 21-8
        // Officers: pin-on nonsubdued rank on shoulder loops (para 21-8b)
        // Enlisted: grade insignia on collars (para 21-7)
        // Warrant Officers: shoulder loops like officers

        let ref: String
        switch soldier.rankCategory {
        case .enlisted:
            ref = "DA PAM 670-1, para 21-7"
            return [
                makePlacedItem(id: "rank_left",  at: geometry.leftCollarCenter,         size: 0.75, ref: ref, soldier: soldier),
                makePlacedItem(id: "rank_right", at: geometry.rightCollarCenter,        size: 0.75, ref: ref, soldier: soldier)
            ]
        case .officer, .warrantOfficer:
            ref = "DA PAM 670-1, para 21-8b"
            return [
                makePlacedItem(id: "rank_left",  at: geometry.leftShoulderLoopCenter,  size: 1.0,  ref: ref, soldier: soldier),
                makePlacedItem(id: "rank_right", at: geometry.rightShoulderLoopCenter, size: 1.0,  ref: ref, soldier: soldier)
            ]
        }
    }

    // MARK: - Branch and US Insignia

    private func placeBranchAndUSInsignia(soldier: Soldier) -> [PlacedItem] {
        // DA PAM 670-1, para 21-4 (US insignia), 21-9 (branch insignia)
        // Officers: branch insignia on both lapels, 1-1/4" below top of lapel
        // Enlisted: US insignia on right lapel, branch insignia on left lapel
        var placed: [PlacedItem] = []

        switch soldier.rankCategory {
        case .officer, .warrantOfficer:
            placed.append(makePlacedItem(id: "branch_left",  at: geometry.leftLapelCenter,  size: 1.0, ref: "DA PAM 670-1, para 21-9",  soldier: soldier))
            placed.append(makePlacedItem(id: "branch_right", at: geometry.rightLapelCenter, size: 1.0, ref: "DA PAM 670-1, para 21-9",  soldier: soldier))
        case .enlisted:
            placed.append(makePlacedItem(id: "us_insignia",  at: geometry.rightLapelCenter, size: 1.0, ref: "DA PAM 670-1, para 21-4",  soldier: soldier))
            placed.append(makePlacedItem(id: "branch_left",  at: geometry.leftLapelCenter,  size: 1.0, ref: "DA PAM 670-1, para 21-9",  soldier: soldier))
        }

        return placed
    }

    // MARK: - Tab Placement

    private func placeTabs(tabs: [UniformItem], soldier: Soldier) -> [PlacedItem] {
        // DA PAM 670-1, para 22-16d:
        // Nonsubdued special skill tabs sewn on the coat above the SSI zone on left sleeve.
        // Stack order: Ranger above SF above Sapper above others (by para precedence).
        // TODO: Implement tab stacking logic
        return []
    }

    // MARK: - Sleeve Items

    private func placeSleeveItems(items: [UniformItem], soldier: Soldier) -> [PlacedItem] {
        // DA PAM 670-1, para 21-28 (service stripes), 21-29 (overseas bars)
        // Service stripes: left sleeve, 4" from bottom edge of sleeve
        // Overseas bars: right sleeve, similar pattern
        // TODO: Implement sleeve stripe rendering
        return []
    }

    // MARK: - Helpers

    private func makePlacedItem(id: String, at position: CGPoint, size: CGFloat, ref: String, soldier: Soldier) -> PlacedItem {
        PlacedItem(
            id: id,
            item: UniformItem(id: id, category: .rank, awardCount: 1, devices: []),
            soldier: soldier,
            geometry: geometry,
            regulationPosition: position,
            regulationRotation: .zero,
            adjustedPosition: nil,
            adjustedRotation: nil,
            renderSize: CGSize(
                width:  size * geometry.normalizedUnitsPerInch,
                height: size * geometry.normalizedUnitsPerInch
            ),
            measurements: [],
            regulationRef: ref
        )
    }

    private func lookupPrecedence(_ item: UniformItem) -> Int {
        // TODO: Look up from ribbons.json data loaded at startup
        return DataLoader.shared.ribbons.first(where: { $0.id == item.id })?.precedence ?? 999
    }

    private func groupOf(_ item: UniformItem) -> Int {
        if case .badge(let g) = item.category { return g }
        return 99
    }
}
