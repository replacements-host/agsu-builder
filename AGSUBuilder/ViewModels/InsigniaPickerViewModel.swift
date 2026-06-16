import SwiftUI
import Combine

@MainActor
class InsigniaPickerViewModel: ObservableObject {
    @Published var selectedItems: [UniformItem] = []
    @Published var serviceStripeCount: Int = 0
    @Published var overseasBarCount: Int = 0

    let soldier: Soldier

    init(soldier: Soldier) {
        self.soldier = soldier
    }

    // MARK: - Ribbon Selection

    func isSelected(_ ribbon: RibbonRecord) -> Bool {
        selectedItems.contains(where: { $0.id == ribbon.id && $0.category == .ribbon })
    }

    func toggleRibbon(_ ribbon: RibbonRecord) {
        if let idx = selectedItems.firstIndex(where: { $0.id == ribbon.id }) {
            selectedItems.remove(at: idx)
        } else {
            selectedItems.append(ribbon.toUniformItem())
        }
    }

    func awardCount(for ribbon: RibbonRecord) -> Int {
        selectedItems.first(where: { $0.id == ribbon.id })?.awardCount ?? 1
    }

    func setAwardCount(_ count: Int, for ribbon: RibbonRecord) {
        guard let idx = selectedItems.firstIndex(where: { $0.id == ribbon.id }) else { return }
        selectedItems[idx].awardCount = max(1, count)
    }

    // MARK: - Badge Selection

    func isSelected(_ badge: BadgeRecord) -> Bool {
        selectedItems.contains(where: { $0.id == badge.id })
    }

    func toggleBadge(_ badge: BadgeRecord) {
        if let idx = selectedItems.firstIndex(where: { $0.id == badge.id }) {
            selectedItems.remove(at: idx)
        } else {
            selectedItems.append(badge.toUniformItem())
        }
    }

    // MARK: - ID Badge Selection

    func isSelected(_ idBadge: IDBadgeRecord) -> Bool {
        selectedItems.contains(where: { $0.id == idBadge.id })
    }

    func toggleIDBadge(_ idBadge: IDBadgeRecord) {
        if let idx = selectedItems.firstIndex(where: { $0.id == idBadge.id }) {
            selectedItems.remove(at: idx)
        } else {
            // Max 2 ID badges (one per pocket side)
            let currentCount = selectedItems.filter {
                if case .idBadge = $0.category { return true }
                return false
            }.count
            if currentCount < 2 {
                selectedItems.append(idBadge.toUniformItem())
            }
        }
    }

    // MARK: - Tab Selection

    func isSelected(_ tab: TabRecord) -> Bool {
        selectedItems.contains(where: { $0.id == tab.id })
    }

    func toggleTab(_ tab: TabRecord) {
        if let idx = selectedItems.firstIndex(where: { $0.id == tab.id }) {
            selectedItems.remove(at: idx)
        } else {
            selectedItems.append(tab.toUniformItem())
        }
    }

    // MARK: - Build Final Item List

    var allSelectedItems: [UniformItem] {
        var items = selectedItems
        if serviceStripeCount > 0 {
            items.append(UniformItem(id: "service_stripes", category: .serviceStripe(count: serviceStripeCount), awardCount: serviceStripeCount, devices: []))
        }
        if overseasBarCount > 0 {
            items.append(UniformItem(id: "overseas_bars", category: .overseasBar(count: overseasBarCount), awardCount: overseasBarCount, devices: []))
        }
        return items
    }
}
