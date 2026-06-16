import SwiftUI
import Combine

/// Backing model for the multi-step insignia selection flow (`BuilderFlowView`).
///
/// Tracks selections across five picker screens:
/// 1. Ribbons (`RibbonPickerView`) — any count, unlimited selection
/// 2. Badges (`BadgePickerView`) — one per group slot
/// 3. ID Badges (`IDBadgePickerView`) — maximum **two** (one per pocket side)
/// 4. Tabs (`TabPickerView`) — any count
/// 5. Service stripes + overseas bars (`ServiceStripeView`) — integer counts
///
/// After the user finishes selecting, `allSelectedItems` assembles the complete
/// `[UniformItem]` list that is passed to `CanvasViewModel`.
@MainActor
class InsigniaPickerViewModel: ObservableObject {

    // MARK: - Published State

    /// All toggled items (ribbons, badges, ID badges, tabs).
    @Published var selectedItems:      [UniformItem] = []
    /// Number of 3-year service stripes (0–20) worn on the left sleeve.
    @Published var serviceStripeCount: Int           = 0
    /// Number of overseas service bars (0–20) worn on the right sleeve.
    @Published var overseasBarCount:   Int           = 0

    /// Soldier profile — used for component and branch eligibility filtering.
    let soldier: Soldier

    init(soldier: Soldier) {
        self.soldier = soldier
    }

    // MARK: - Ribbon Selection

    /// Returns `true` if the given ribbon is currently selected.
    func isSelected(_ ribbon: RibbonRecord) -> Bool {
        selectedItems.contains { $0.id == ribbon.id && $0.category == .ribbon }
    }

    /// Toggles a ribbon in/out of the selection list.
    func toggleRibbon(_ ribbon: RibbonRecord) {
        if let idx = selectedItems.firstIndex(where: { $0.id == ribbon.id }) {
            selectedItems.remove(at: idx)
        } else {
            selectedItems.append(ribbon.toUniformItem())
        }
    }

    /// Returns the current award count for a selected ribbon (default 1).
    func awardCount(for ribbon: RibbonRecord) -> Int {
        selectedItems.first { $0.id == ribbon.id }?.awardCount ?? 1
    }

    /// Updates the award count (minimum 1) for an already-selected ribbon.
    func setAwardCount(_ count: Int, for ribbon: RibbonRecord) {
        guard let idx = selectedItems.firstIndex(where: { $0.id == ribbon.id }) else { return }
        selectedItems[idx].awardCount = max(1, count)
    }

    // MARK: - Badge Selection

    /// Returns `true` if the given badge is currently selected.
    func isSelected(_ badge: BadgeRecord) -> Bool {
        selectedItems.contains { $0.id == badge.id }
    }

    /// Toggles a badge in/out of the selection list.
    func toggleBadge(_ badge: BadgeRecord) {
        if let idx = selectedItems.firstIndex(where: { $0.id == badge.id }) {
            selectedItems.remove(at: idx)
        } else {
            selectedItems.append(badge.toUniformItem())
        }
    }

    // MARK: - ID Badge Selection

    /// Returns `true` if the given ID badge is currently selected.
    func isSelected(_ idBadge: IDBadgeRecord) -> Bool {
        selectedItems.contains { $0.id == idBadge.id }
    }

    /// Toggles an ID badge, enforcing the **two-badge maximum** (one per pocket).
    /// A third selection is silently ignored; the UI should disable the row when
    /// `selectedIDCount == 2` and the badge is not already selected.
    func toggleIDBadge(_ idBadge: IDBadgeRecord) {
        if let idx = selectedItems.firstIndex(where: { $0.id == idBadge.id }) {
            selectedItems.remove(at: idx)
        } else {
            let currentCount = selectedItems.filter {
                if case .idBadge = $0.category { return true }
                return false
            }.count
            // DA PAM 670-1, para 22-17: maximum one badge per pocket side
            if currentCount < 2 {
                selectedItems.append(idBadge.toUniformItem())
            }
        }
    }

    // MARK: - Tab Selection

    /// Returns `true` if the given tab is currently selected.
    func isSelected(_ tab: TabRecord) -> Bool {
        selectedItems.contains { $0.id == tab.id }
    }

    /// Toggles a tab in/out of the selection list.
    func toggleTab(_ tab: TabRecord) {
        if let idx = selectedItems.firstIndex(where: { $0.id == tab.id }) {
            selectedItems.remove(at: idx)
        } else {
            selectedItems.append(tab.toUniformItem())
        }
    }

    // MARK: - Final Item Assembly

    /// Combines all toggled items with sleeve counts into the list passed to `PlacementEngine`.
    var allSelectedItems: [UniformItem] {
        var items = selectedItems
        if serviceStripeCount > 0 {
            items.append(UniformItem(
                id:          "service_stripes",
                category:    .serviceStripe(count: serviceStripeCount),
                awardCount:  serviceStripeCount,
                devices:     []
            ))
        }
        if overseasBarCount > 0 {
            items.append(UniformItem(
                id:          "overseas_bars",
                category:    .overseasBar(count: overseasBarCount),
                awardCount:  overseasBarCount,
                devices:     []
            ))
        }
        return items
    }
}
