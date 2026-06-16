import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var rankCategory: Soldier.RankCategory = .enlisted
    @Published var grade: String = "E-5"
    @Published var branch: String = "infantry"
    @Published var component: Soldier.Component = .active
    @Published var gender: Soldier.Gender = .male
    @Published var isCombatVeteran: Bool = false

    var soldier: Soldier {
        Soldier(
            rankCategory: rankCategory,
            grade: grade,
            branch: branch,
            component: component,
            gender: gender,
            isCombatVeteran: isCombatVeteran
        )
    }

    var availableGrades: [String] {
        switch rankCategory {
        case .enlisted:
            return ["E-1", "E-2", "E-3", "E-4", "E-5", "E-6", "E-7", "E-8", "E-9"]
        case .warrantOfficer:
            return ["W-1", "W-2", "W-3", "W-4", "W-5"]
        case .officer:
            return ["O-1", "O-2", "O-3", "O-4", "O-5", "O-6", "O-7", "O-8", "O-9", "O-10"]
        }
    }

    var gradeTitle: [String: String] {
        [
            "E-1": "Private", "E-2": "Private Second Class",
            "E-3": "Private First Class", "E-4": "Specialist / Corporal",
            "E-5": "Sergeant", "E-6": "Staff Sergeant",
            "E-7": "Sergeant First Class", "E-8": "Master Sergeant / First Sergeant",
            "E-9": "Sergeant Major / Command Sergeant Major / Sergeant Major of the Army",
            "W-1": "Warrant Officer 1", "W-2": "Chief Warrant Officer 2",
            "W-3": "Chief Warrant Officer 3", "W-4": "Chief Warrant Officer 4",
            "W-5": "Chief Warrant Officer 5",
            "O-1": "Second Lieutenant", "O-2": "First Lieutenant",
            "O-3": "Captain", "O-4": "Major", "O-5": "Lieutenant Colonel",
            "O-6": "Colonel", "O-7": "Brigadier General",
            "O-8": "Major General", "O-9": "Lieutenant General",
            "O-10": "General"
        ]
    }

    var availableBranches: [BranchRecord] {
        DataLoader.shared.branchInsignia
    }

    func updateGradeForCategory() {
        grade = availableGrades.first ?? grade
    }
}
