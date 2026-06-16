import Foundation

/// A persisted uniform configuration.
///
/// Stored as a plain `Codable` struct and written to a JSON file in the app's
/// Documents directory by `SavedUniformsViewModel`. Using a flat file instead of
/// SwiftData keeps the minimum deployment target at iOS 16 and avoids the
/// `@Model` macro, which requires iOS 17+.
///
/// Schema note — flat soldier fields vs. JSON blobs:
/// - Soldier profile fields are stored flat so list rows can display grade/branch
///   without deserializing the full item payload.
/// - Items and adjustments are stored as JSON strings because the item graph
///   does not need relational querying — the whole payload is always loaded together.
struct SavedUniform: Codable, Identifiable {

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

    /// Decodes the saved `itemsJSON` blob and reconstructs `UniformItem` values
    /// by looking each id up in `DataLoader`. Items whose ids are no longer in
    /// the data files (e.g. regulation changes) are silently dropped.
    func toUniformItems() -> [UniformItem] {
        guard let data = itemsJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return json.compactMap { dict in
            guard let id = dict["id"] as? String else { return nil }
            let awardCount = dict["awardCount"] as? Int    ?? 1
            let devices    = dict["devices"]    as? [String] ?? []
            return DataLoader.shared.findItem(id: id, awardCount: awardCount, devices: devices)
        }
    }
}
