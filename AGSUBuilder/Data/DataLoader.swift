import Foundation
import Combine

/// Singleton that loads and exposes all JSON regulation data.
///
/// `DataLoader` is the single source of truth for award records. It reads bundled
/// JSON files on first launch, publishes the decoded arrays, and (via the TODO stub)
/// will eventually download updated JSON when a newer `regulation_version.json` is found.
///
/// **Usage:**
/// ```swift
/// DataLoader.shared.loadAll()          // called once in AGSUBuilderApp.onAppear
/// let ribbons = DataLoader.shared.ribbons(for: soldier)   // filtered by component
/// ```
///
/// **Remote update flow (not yet implemented):**
/// 1. Load `regulation_version.json` from the bundle.
/// 2. Fetch the version manifest from `remoteURL`.
/// 3. If the remote version is newer, download updated JSON files.
/// 4. Cache in Application Support. On next launch, prefer cached files.
class DataLoader: ObservableObject {

    // MARK: - Singleton

    static let shared = DataLoader()

    // MARK: - Published Data

    @Published private(set) var ribbons:        [RibbonRecord]  = []
    @Published private(set) var badges:         [BadgeRecord]   = []
    @Published private(set) var tabs:           [TabRecord]     = []
    @Published private(set) var idBadges:       [IDBadgeRecord] = []
    @Published private(set) var rankInsignia:   [RankRecord]    = []
    @Published private(set) var branchInsignia: [BranchRecord]  = []

    // MARK: - Load

    /// Decodes all bundled JSON files and publishes the results.
    /// Safe to call multiple times; later calls overwrite earlier data.
    func loadAll() {
        ribbons        = load("ribbons")
        badges         = load("badges")
        tabs           = load("tabs")
        idBadges       = load("id_badges")
        rankInsignia   = load("rank_insignia")
        branchInsignia = load("branch_insignia")
        checkForRemoteUpdates()
    }

    /// Generic JSON decoder that reads a named resource file from the main bundle.
    /// Returns an empty array on any error (missing file, malformed JSON, type mismatch).
    private func load<T: Decodable>(_ name: String) -> [T] {
        guard let url  = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return [] }
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }

    /// Checks whether a newer regulation version is available at the remote URL
    /// recorded in `regulation_version.json` and downloads updated data files if so.
    private func checkForRemoteUpdates() {
        // TODO: Load regulation_version.json (single object, not array — use JSONDecoder directly).
        // Compare bundled version string to cached remote version.
        // If remote is newer, URLSession.download updated JSON into Application Support,
        // then call loadAll() again from the cache directory.
    }

    // MARK: - Filtered Access

    /// Returns ribbons eligible for the given soldier's component.
    func ribbons(for soldier: Soldier) -> [RibbonRecord] {
        ribbons.filter { $0.eligibleComponents.contains(soldier.component.jsonKey) }
    }

    /// Returns badges eligible by both branch and component.
    /// An empty `eligibleBranches` array means "all branches".
    func badges(for soldier: Soldier) -> [BadgeRecord] {
        badges.filter { badge in
            let branchMatch = badge.eligibleBranches.isEmpty
                || badge.eligibleBranches.contains(soldier.branch.lowercased())
                || badge.eligibleBranches.contains("all")
            let componentMatch = badge.eligibleComponents.contains(soldier.component.jsonKey)
            return branchMatch && componentMatch
        }
    }

    /// Returns ID badges eligible for the given soldier's component.
    func idBadges(for soldier: Soldier) -> [IDBadgeRecord] {
        idBadges.filter { $0.eligibleComponents.contains(soldier.component.jsonKey) }
    }

    /// Returns rank records matching the given category ("enlisted", "officer", "warrant_officer").
    func rankRecords(for category: Soldier.RankCategory) -> [RankRecord] {
        let key: String
        switch category {
        case .enlisted:       key = "enlisted"
        case .officer:        key = "officer"
        case .warrantOfficer: key = "warrant_officer"
        }
        return rankInsignia.filter { $0.category == key }
    }

    /// Looks up any selectable item by ID across ribbons, badges, ID badges, and tabs.
    /// Rank and branch insignia are auto-placed from the soldier profile and are not returned here.
    func findItem(id: String, awardCount: Int = 1, devices: [String] = []) -> UniformItem? {
        if let r = ribbons.first(where: { $0.id == id }) {
            return r.toUniformItem(awardCount: awardCount, devices: devices)
        }
        if let b = badges.first(where: { $0.id == id }) {
            return b.toUniformItem(awardCount: awardCount)
        }
        if let ib = idBadges.first(where: { $0.id == id }) {
            return ib.toUniformItem()
        }
        if let t = tabs.first(where: { $0.id == id }) {
            return t.toUniformItem()
        }
        return nil
    }
}
