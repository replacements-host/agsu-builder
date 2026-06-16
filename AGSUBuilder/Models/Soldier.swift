import Foundation

struct Soldier {
    enum RankCategory: String, CaseIterable {
        case enlisted = "Enlisted"
        case officer = "Officer"
        case warrantOfficer = "Warrant Officer"
    }

    enum Component: String, CaseIterable {
        case active = "Active"
        case reserve = "Reserve"
        case guard = "Guard"

        var jsonKey: String { rawValue.lowercased() }
    }

    enum Gender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
    }

    var rankCategory: RankCategory
    var grade: String      // "E-5", "O-3", "W-2", etc.
    var branch: String     // "infantry", "signal", etc.
    var component: Component
    var gender: Gender
    var isCombatVeteran: Bool = false

    var coatVariant: CoatVariant {
        switch (rankCategory, gender) {
        case (.enlisted, .male):          return .enlistedMale
        case (.enlisted, .female):        return .enlistedFemale
        case (.officer, .male):           return .officerMale
        case (.officer, .female):         return .officerFemale
        case (.warrantOfficer, .male):    return .officerMale
        case (.warrantOfficer, .female):  return .officerFemale
        }
    }

    static var `default`: Soldier {
        Soldier(rankCategory: .enlisted, grade: "E-5", branch: "infantry",
                component: .active, gender: .male)
    }
}

enum CoatVariant: String {
    case officerMale, officerFemale, enlistedMale, enlistedFemale

    var assetName: String {
        switch self {
        case .officerMale:    return "fig14_1_officer_male"
        case .officerFemale:  return "fig14_2_officer_female"
        case .enlistedMale:   return "fig14_3_enlisted_male"
        case .enlistedFemale: return "fig14_4_enlisted_female"
        }
    }

    var displayLabel: String {
        switch self {
        case .officerMale:    return "Officer Male Coat"
        case .officerFemale:  return "Officer Female Coat"
        case .enlistedMale:   return "Enlisted Male Coat"
        case .enlistedFemale: return "Enlisted Female Coat"
        }
    }

    var geometry: CoatGeometry {
        switch self {
        case .officerMale:    return CoatGeometry.officerMale
        case .officerFemale:  return CoatGeometry.officerFemale
        case .enlistedMale:   return CoatGeometry.enlistedMale
        case .enlistedFemale: return CoatGeometry.enlistedFemale
        }
    }
}
