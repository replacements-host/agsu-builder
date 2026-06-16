import Foundation

struct UniformItem: Identifiable, Equatable {
    let id: String          // matches JSON id field
    let category: ItemCategory
    var awardCount: Int     // for oak leaf clusters, etc.
    var devices: [String]   // ["v_device", "oak_leaf_cluster"]

    static func == (lhs: UniformItem, rhs: UniformItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum ItemCategory: Equatable {
    case ribbon
    case badge(group: Int)
    case idBadge
    case tab
    case serviceStripe(count: Int)
    case overseasBar(count: Int)
    case rank
    case branchInsignia
    case usInsignia

    static func == (lhs: ItemCategory, rhs: ItemCategory) -> Bool {
        switch (lhs, rhs) {
        case (.ribbon, .ribbon): return true
        case (.badge(let a), .badge(let b)): return a == b
        case (.idBadge, .idBadge): return true
        case (.tab, .tab): return true
        case (.serviceStripe(let a), .serviceStripe(let b)): return a == b
        case (.overseasBar(let a), .overseasBar(let b)): return a == b
        case (.rank, .rank): return true
        case (.branchInsignia, .branchInsignia): return true
        case (.usInsignia, .usInsignia): return true
        default: return false
        }
    }

    var displayName: String {
        switch self {
        case .ribbon: return "Ribbon"
        case .badge(let g): return "Badge (Group \(g))"
        case .idBadge: return "ID Badge"
        case .tab: return "Tab"
        case .serviceStripe: return "Service Stripe"
        case .overseasBar: return "Overseas Bar"
        case .rank: return "Rank"
        case .branchInsignia: return "Branch Insignia"
        case .usInsignia: return "U.S. Insignia"
        }
    }
}

// MARK: - JSON-decodable record types

struct RibbonRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let shortName: String
    let precedence: Int
    let category: String
    let imageAsset: String
    let authorizedDevices: [String]
    let devicesOrientedToWearer: Bool
    let eligibleComponents: [String]
    let regulationRef: String

    func toUniformItem(awardCount: Int = 1, devices: [String] = []) -> UniformItem {
        UniformItem(id: id, category: .ribbon, awardCount: awardCount, devices: devices)
    }
}

struct BadgeRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let shortName: String
    let group: Int
    let tier: Int
    let imageAsset: String
    let eligibleBranches: [String]
    let eligibleComponents: [String]
    let regulationRef: String
    let hasMultipleAwards: Bool
    let maxAwards: Int

    func toUniformItem(awardCount: Int = 1) -> UniformItem {
        UniformItem(id: id, category: .badge(group: group), awardCount: awardCount, devices: [])
    }
}

struct IDBadgeRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let imageAsset: String
    let pocketSide: String
    let eligibleComponents: [String]
    let regulationRef: String

    func toUniformItem() -> UniformItem {
        UniformItem(id: id, category: .idBadge, awardCount: 1, devices: [])
    }
}

struct TabRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let imageAsset: String
    let sleevePosition: String
    let stackOrder: Int
    let regulationRef: String

    func toUniformItem() -> UniformItem {
        UniformItem(id: id, category: .tab, awardCount: 1, devices: [])
    }
}

struct RankRecord: Decodable, Identifiable {
    let id: String
    let grade: String
    let title: String
    let category: String  // "enlisted", "officer", "warrant_officer"
    let imageAsset: String
    let regulationRef: String
}

struct BranchRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let imageAsset: String
    let regulationRef: String
}

struct ServiceStripeRecord: Decodable {
    let yearsPerStripe: Int
    let color: String
    let regulationRef: String
}

struct OverseasBarRecord: Decodable {
    let campaignsPerBar: Int
    let color: String
    let regulationRef: String
}

struct RegulationVersionRecord: Decodable {
    let version: String
    let date: String
    let remoteURL: String?

    enum CodingKeys: String, CodingKey {
        case version, date, remoteURL = "remote_url"
    }
}
