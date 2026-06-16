import Foundation

/// Immutable value type representing a Soldier's profile.
///
/// All placement and filtering logic queries the `Soldier` value to:
/// - Select the correct `CoatVariant` (and therefore `CoatGeometry`)
/// - Filter eligible awards by component
/// - Compute gender-aware out-of-policy thresholds in `PlacedItem`
struct Soldier {

    // MARK: - Nested Types

    /// Broad pay-grade grouping. Drives coat variant selection and
    /// rank insignia placement (collar vs. shoulder loop).
    enum RankCategory: String, CaseIterable {
        case enlisted       = "Enlisted"
        case officer        = "Officer"
        case warrantOfficer = "Warrant Officer"
    }

    /// Army component controlling which awards are eligible.
    /// Mirrors the `eligibleComponents` JSON key values.
    enum Component: String, CaseIterable {
        case active  = "Active"
        case reserve = "Reserve"
        case `guard` = "Guard"

        /// Lowercase string used as a JSON filter key.
        var jsonKey: String { rawValue.lowercased() }
    }

    /// Biological sex as recorded in service records.
    /// Used for body-shape adjustment authorization and out-of-policy threshold:
    /// female: 1/4 inch, male: 1/8 inch (see `PlacedItem.isOutOfPolicy`).
    enum Gender: String, CaseIterable {
        case male   = "Male"
        case female = "Female"
    }

    // MARK: - Properties

    var rankCategory:     RankCategory
    /// Pay grade string, e.g. "E-5", "O-3", "W-2".
    var grade:            String
    /// Branch identifier matching `BranchRecord.id`, e.g. "infantry", "signal_corps".
    var branch:           String
    var component:        Component
    var gender:           Gender
    /// Whether the Soldier has qualifying combat service (affects CSIB eligibility).
    var isCombatVeteran:  Bool = false

    // MARK: - Computed

    /// Selects the coat image and geometry based on rank category and gender.
    /// Warrant Officers use the officer coat silhouette per DA PAM 670-1, Fig. 14-1.
    var coatVariant: CoatVariant {
        switch (rankCategory, gender) {
        case (.enlisted,       .male):   return .enlistedMale
        case (.enlisted,       .female): return .enlistedFemale
        case (.officer,        .male):   return .officerMale
        case (.officer,        .female): return .officerFemale
        case (.warrantOfficer, .male):   return .officerMale
        case (.warrantOfficer, .female): return .officerFemale
        }
    }

    // MARK: - Defaults

    /// A sensible default used for SwiftUI previews and first-launch state.
    static var `default`: Soldier {
        Soldier(rankCategory: .enlisted, grade: "E-5", branch: "infantry",
                component: .active, gender: .male)
    }
}

// MARK: - CoatVariant

/// The four AGSU coat silhouette variants referenced in DA PAM 670-1,
/// Figures 14-1 through 14-4.
///
/// There is **no `assetName` property** — the coat is not an image asset. It is
/// drawn at runtime by `CoatLayerView` using the `Path` geometry in `CoatGeometry`.
///
/// Officer and enlisted share the same coat *cut* per gender (only insignia placement
/// rules differ — those live in `PlacementEngine`). The four cases are kept as
/// separate enum values because `PlacementEngine` branches on rank category
/// independently of coat geometry.
enum CoatVariant: String {
    case officerMale, officerFemale, enlistedMale, enlistedFemale

    /// Returns the coat drawing and insignia placement geometry for this variant.
    /// Officer and enlisted share the same geometry per gender.
    var geometry: CoatGeometry {
        switch self {
        case .officerMale, .enlistedMale:     return CoatGeometry.male
        case .officerFemale, .enlistedFemale: return CoatGeometry.female
        }
    }
}
