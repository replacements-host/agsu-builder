import Foundation
import SwiftData

/// SwiftData model representing a persisted uniform configuration.
///
/// SwiftData requires all stored properties to be basic value types (String, Int, Bool,
/// Date, UUID). Complex types (`Soldier`, `UniformItem`, `UniformConfiguration`) are
/// encoded as JSON strings and decoded on demand via the `toX()` helper methods.
///
/// Schema rationale — flat fields vs. JSON blobs:
/// - Soldier profile fields are stored flat so they can be displayed in list rows
///   without deserializing the full item payload.
/// - Items and adjustments are stored as JSON strings because SwiftData does not
///   support nested `Codable` types in the same model container without custom migration.
@Model
class SavedUniform {

    // MARK: - Identity

    var id: UUID
    /// User-assigned name, e.g. "SFC Smith — Korea Deployment".
    var name: String
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Soldier Profile (flat fields for list-row access)

    var rankCategory: String  // Soldier.RankCategory.rawValue
    var grade: String         // e.g. "E-7"
    var branch: String        // e.g. "infantry"
    var component: String     // Soldier.Component.rawValue
    var gender: String        // Soldier.Gender.rawValue
    var isCombatVeteran: Bool

    // MARK: - Selected Items (JSON-encoded)

    /// JSON array: `[{"id": "...", "awardCount": 1, "devices": []}]`
    var itemsJSON: String

    /// JSON dictionary: `{"itemId": {"x": 0.42, "y": 0.38, "rotation": 0.0}}`
    var adjustmentsJSON: String

    // MARK: - Ribbon Rack Configuration

    var ribbonsPerRow: Int                // 3 or 4
    var ribbonRowSpacing: String          // "none" | "eighth_inch"
    var ribbonTopRowAlignment: String     // "centered" | "left"
    var badgeGroupThreePosition: String   // "above" | "below"

    // MARK: - Initializer

    /// Creates a new saved uniform with default ribbon rack settings and empty item lists.
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

    // MARK: - Deserialization

    /// Reconstructs the `Soldier` value from stored flat fields.
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

    /// Reconstructs the `UniformConfiguration` from stored ribbon-rack fields.
    func toConfiguration() -> UniformConfiguration {
        UniformConfiguration(
            ribbonsPerRow: ribbonsPerRow,
            ribbonRowSpacing: ribbonRowSpacing,
            ribbonTopRowAlignment: ribbonTopRowAlignment,
            badgeGroupThreePosition: badgeGroupThreePosition
        )
    }
}
