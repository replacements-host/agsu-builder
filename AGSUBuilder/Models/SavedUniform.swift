import Foundation
import SwiftData

@Model
class SavedUniform {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    // Soldier profile
    var rankCategory: String
    var grade: String
    var branch: String
    var component: String
    var gender: String
    var isCombatVeteran: Bool

    // Selected items (JSON: [{id, category, awardCount, devices}])
    var itemsJSON: String

    // Adjust mode overrides (JSON: {itemId: {x, y, rotation}})
    var adjustmentsJSON: String

    // Ribbon rack configuration
    var ribbonsPerRow: Int
    var ribbonRowSpacing: String
    var ribbonTopRowAlignment: String
    var badgeGroupThreePosition: String

    init(name: String, soldier: Soldier) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.rankCategory = soldier.rankCategory.rawValue
        self.grade = soldier.grade
        self.branch = soldier.branch
        self.component = soldier.component.rawValue
        self.gender = soldier.gender.rawValue
        self.isCombatVeteran = soldier.isCombatVeteran
        self.ribbonsPerRow = 3
        self.ribbonRowSpacing = "none"
        self.ribbonTopRowAlignment = "centered"
        self.badgeGroupThreePosition = "above"
        self.itemsJSON = "[]"
        self.adjustmentsJSON = "{}"
    }

    func toSoldier() -> Soldier {
        Soldier(
            rankCategory: Soldier.RankCategory(rawValue: rankCategory) ?? .enlisted,
            grade: grade,
            branch: branch,
            component: Soldier.Component(rawValue: component) ?? .active,
            gender: Soldier.Gender(rawValue: gender) ?? .male,
            isCombatVeteran: isCombatVeteran
        )
    }

    func toConfiguration() -> UniformConfiguration {
        UniformConfiguration(
            ribbonsPerRow: ribbonsPerRow,
            ribbonRowSpacing: ribbonRowSpacing,
            ribbonTopRowAlignment: ribbonTopRowAlignment,
            badgeGroupThreePosition: badgeGroupThreePosition
        )
    }
}
