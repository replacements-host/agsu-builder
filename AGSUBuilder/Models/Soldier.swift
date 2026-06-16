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
        case guard   = "Guard"

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

/// The four distinct AGSU coat silhouettes referenced in DA PAM 670-1,
/// Figures 14-1 through 14-4. Each variant has its own:
/// - Asset name (gray placeholder PNG until replaced by real artwork)
/// - Human-readable label for the fallback view
/// - Calibrated (or placeholder) `CoatGeometry`
enum CoatVariant: String {
    case officerMale, officerFemale, enlistedMale, enlistedFemale

    /// Asset catalog name inside `Assets.xcassets/Coat/`.
    var assetName: String {
        switch self {
        case .officerMale:    return "fig14_1_officer_male"
        case .officerFemale:  return "fig14_2_officer_female"
        case .enlistedMale:   return "fig14_3_enlisted_male"
        case .enlistedFemale: return "fig14_4_enlisted_female"
        }
    }

    /// Short label displayed on the gray placeholder when no coat image is found.
    var displayLabel: String {
        switch self {
        case .officerMale:    return "Officer Male Coat"
        case .officerFemale:  return "Officer Female Coat"
        case .enlistedMale:   return "Enlisted Male Coat"
        case .enlistedFemale: return "Enlisted Female Coat"
        }
    }

    /// Normalized anchor-point geometry for this coat.
    /// Values are PLACEHOLDER presets — do not calibrate in code.
    var geometry: CoatGeometry {
        switch self {
        case .officerMale:    return CoatGeometry.officerMale
        case .officerFemale:  return CoatGeometry.officerFemale
        case .enlistedMale:   return CoatGeometry.enlistedMale
        case .enlistedFemale: return CoatGeometry.enlistedFemale
        }
    }
}
