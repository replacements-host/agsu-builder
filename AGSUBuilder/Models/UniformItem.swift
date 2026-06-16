import Foundation

/// A single selectable uniform item chosen by the user.
///
/// `UniformItem` is the canonical in-memory representation for anything that
/// can be placed on the coat. It is created from JSON record types via their
/// `toUniformItem()` helpers and passed to `PlacementEngine.place(items:soldier:)`.
struct UniformItem: Identifiable, Equatable {
    /// Matches the `id` field in the corresponding JSON record.
    let id: String
    /// Determines the placement group and render size.
    let category: ItemCategory
    /// Number of times this award has been earned (drives oak-leaf-cluster / numeral device rendering).
    var awardCount: Int
    /// Authorized attachment devices, e.g. `["v_device", "oak_leaf_cluster"]`.
    var devices: [String]

    static func == (lhs: UniformItem, rhs: UniformItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ItemCategory

/// Discriminated union describing how an item is placed and rendered.
///
/// Associated values carry item-specific metadata needed by `PlacementEngine`:
/// - `badge(group:)` — DA PAM 670-1 badge group number (1–5) controlling precedence
/// - `serviceStripe(count:)` — number of 3-year stripes to render on left sleeve
/// - `overseasBar(count:)` — number of campaign bars to render on right sleeve
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
        case (.ribbon, .ribbon):                             return true
        case (.badge(let a), .badge(let b)):                 return a == b
        case (.idBadge, .idBadge):                          return true
        case (.tab, .tab):                                   return true
        case (.serviceStripe(let a), .serviceStripe(let b)): return a == b
        case (.overseasBar(let a),   .overseasBar(let b)):   return a == b
        case (.rank, .rank):                                 return true
        case (.branchInsignia, .branchInsignia):             return true
        case (.usInsignia, .usInsignia):                     return true
        default:                                             return false
        }
    }

    /// Short human-readable label used in the inspector and detail sheet.
    var displayName: String {
        switch self {
        case .ribbon:                   return "Ribbon"
        case .badge(let g):             return "Badge (Group \(g))"
        case .idBadge:                  return "ID Badge"
        case .tab:                      return "Tab"
        case .serviceStripe:            return "Service Stripe"
        case .overseasBar:              return "Overseas Bar"
        case .rank:                     return "Rank"
        case .branchInsignia:           return "Branch Insignia"
        case .usInsignia:               return "U.S. Insignia"
        }
    }
}

// MARK: - JSON Record Types

/// Mirrors one entry in `ribbons.json`.
///
/// Key fields:
/// - `precedence`: lower number = higher precedence (worn closest to center)
/// - `devicesOrientedToWearer`: `true` for Armed Forces Reserve Medal — devices face
///   the wearer, not the viewer. This is a documented iUniform bug fix.
struct RibbonRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let shortName: String
    /// Lower number = higher precedence per DA PAM 670-1, para 22-6.
    let precedence: Int
    let category: String
    let imageAsset: String
    let authorizedDevices: [String]
    /// When `true`, attachment devices are oriented to face the wearer rather
    /// than the viewer. Affects device overlay rendering in `InsigniaLayerView`.
    let devicesOrientedToWearer: Bool
    let eligibleComponents: [String]
    let regulationRef: String

    func toUniformItem(awardCount: Int = 1, devices: [String] = []) -> UniformItem {
        UniformItem(id: id, category: .ribbon, awardCount: awardCount, devices: devices)
    }
}

/// Mirrors one entry in `badges.json`.
struct BadgeRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let shortName: String
    /// DA PAM 670-1 badge group (1–5). Controls vertical stacking order above ribbon rack.
    let group: Int
    /// Within-group precedence tier (lower = higher precedence when multiple badges
    /// compete for the same group slot).
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

/// Mirrors one entry in `id_badges.json`.
///
/// `pocketSide` is "right" for CSIB and "left" for all other ID badges.
struct IDBadgeRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let imageAsset: String
    /// "left" or "right" — CSIB always goes on the right pocket (DA PAM 670-1, para 22-17).
    let pocketSide: String
    let eligibleComponents: [String]
    let regulationRef: String

    func toUniformItem() -> UniformItem {
        UniformItem(id: id, category: .idBadge, awardCount: 1, devices: [])
    }
}

/// Mirrors one entry in `tabs.json`.
struct TabRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let imageAsset: String
    /// "left" — all tabs worn on the left shoulder sleeve (DA PAM 670-1, para 22-16d).
    let sleevePosition: String
    /// Vertical stacking order when multiple tabs are worn; lower number = higher on sleeve.
    let stackOrder: Int
    let regulationRef: String

    func toUniformItem() -> UniformItem {
        UniformItem(id: id, category: .tab, awardCount: 1, devices: [])
    }
}

/// Mirrors one entry in `rank_insignia.json`.
struct RankRecord: Decodable, Identifiable {
    let id: String
    let grade: String
    let title: String
    /// Raw string: "enlisted", "officer", or "warrant_officer".
    let category: String
    let imageAsset: String
    let regulationRef: String
}

/// Mirrors one entry in `branch_insignia.json`.
struct BranchRecord: Decodable, Identifiable {
    let id: String
    let name: String
    let imageAsset: String
    let regulationRef: String
}

/// Mirrors the single object in `service_stripes.json`.
/// Service stripes are not individual selectable items — `DataLoader` reads this record
/// to understand the 3-years-per-stripe rule; count is collected via `ServiceStripeView`.
struct ServiceStripeRecord: Decodable {
    let yearsPerStripe: Int
    let color: String
    let regulationRef: String
}

/// Mirrors the single object in `overseas_bars.json`.
struct OverseasBarRecord: Decodable {
    let campaignsPerBar: Int
    let color: String
    let regulationRef: String
}

/// Mirrors the single object in `regulation_version.json`.
/// Used by the remote-update stub to detect when bundled JSON data is stale.
struct RegulationVersionRecord: Decodable {
    let version: String
    let date: String
    /// Optional URL to a hosted JSON manifest. Nil in offline mode.
    let remoteURL: String?

    enum CodingKeys: String, CodingKey {
        case version, date, remoteURL = "remote_url"
    }
}
