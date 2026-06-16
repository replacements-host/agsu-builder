import Foundation
import Combine

class DataLoader: ObservableObject {
    static let shared = DataLoader()

    @Published private(set) var ribbons: [RibbonRecord] = []
    @Published private(set) var badges: [BadgeRecord] = []
    @Published private(set) var tabs: [TabRecord] = []
    @Published private(set) var idBadges: [IDBadgeRecord] = []
    @Published private(set) var rankInsignia: [RankRecord] = []
    @Published private(set) var branchInsignia: [BranchRecord] = []

    func loadAll() {
        ribbons       = load("ribbons")
        badges        = load("badges")
        tabs          = load("tabs")
        idBadges      = load("id_badges")
        rankInsignia  = load("rank_insignia")
        branchInsignia = load("branch_insignia")
        checkForRemoteUpdates()
    }

    private func load<T: Decodable>(_ name: String) -> [T] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }

    private func checkForRemoteUpdates() {
        // TODO: Load regulation_version.json, compare version to cached remote version,
        // download updated JSON files if newer version available.
        // Cache downloaded files in Application Support directory.
        // On next launch, prefer cached files over bundled files if version is newer.
    }

    // MARK: - Filtered Access

    func ribbons(for soldier: Soldier) -> [RibbonRecord] {
        ribbons.filter { $0.eligibleComponents.contains(soldier.component.jsonKey) }
    }

    func badges(for soldier: Soldier) -> [BadgeRecord] {
        badges.filter { badge in
            let branchMatch = badge.eligibleBranches.isEmpty ||
                badge.eligibleBranches.contains(soldier.branch.lowercased()) ||
                badge.eligibleBranches.contains("all")
            let componentMatch = badge.eligibleComponents.contains(soldier.component.jsonKey)
            return branchMatch && componentMatch
        }
    }

    func idBadges(for soldier: Soldier) -> [IDBadgeRecord] {
        idBadges.filter { $0.eligibleComponents.contains(soldier.component.jsonKey) }
    }

    func rankRecords(for category: Soldier.RankCategory) -> [RankRecord] {
        let key: String
        switch category {
        case .enlisted:        key = "enlisted"
        case .officer:         key = "officer"
        case .warrantOfficer:  key = "warrant_officer"
        }
        return rankInsignia.filter { $0.category == key }
    }
}
