import SwiftUI

struct BadgePickerView: View {
    @ObservedObject var vm: InsigniaPickerViewModel

    private var groupedBadges: [(Int, [BadgeRecord])] {
        let eligible = DataLoader.shared.badges(for: vm.soldier)
        let groups = Dictionary(grouping: eligible) { $0.group }
        return groups.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    var body: some View {
        List {
            ForEach(groupedBadges, id: \.0) { group, badges in
                Section {
                    ForEach(badges) { badge in
                        BadgeRow(badge: badge, vm: vm)
                            .listRowBackground(Color(.secondarySystemBackground))
                    }
                } header: {
                    Text(groupName(group))
                        .font(AppFont.sectionHeader)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func groupName(_ group: Int) -> String {
        switch group {
        case 1: return "GROUP 1 — COMBAT BADGES"
        case 2: return "GROUP 2 — EXPERT BADGES"
        case 3: return "GROUP 3 — AVIATION & SPECIAL SKILL"
        case 4: return "GROUP 4 — PARACHUTIST & SPECIAL"
        case 5: return "GROUP 5 — DRIVER & MARKSMANSHIP"
        default: return "GROUP \(group)"
        }
    }
}

struct BadgeRow: View {
    let badge: BadgeRecord
    @ObservedObject var vm: InsigniaPickerViewModel

    var isSelected: Bool { vm.isSelected(badge) }

    var body: some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .overlay(
                    Image(badge.imageAsset)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                )
                .frame(width: 48, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(badge.name)
                    .font(AppFont.bodyPrimary)
                    .foregroundColor(Color(.label))
                Text(badge.regulationRef)
                    .font(AppFont.caption)
                    .foregroundColor(Color(.tertiaryLabel))
                if !badge.eligibleBranches.isEmpty && badge.eligibleBranches != ["all"] {
                    Text(badge.eligibleBranches.joined(separator: ", ").capitalized)
                        .font(AppFont.caption)
                        .foregroundColor(.brandGold)
                }
            }

            Spacer()

            if badge.hasMultipleAwards {
                if isSelected {
                    Stepper("\(vm.selectedItems.first(where: { $0.id == badge.id })?.awardCount ?? 1)×", value: Binding(
                        get: { vm.selectedItems.first(where: { $0.id == badge.id })?.awardCount ?? 1 },
                        set: { newVal in
                            if let idx = vm.selectedItems.firstIndex(where: { $0.id == badge.id }) {
                                vm.selectedItems[idx].awardCount = min(newVal, badge.maxAwards)
                            }
                        }
                    ), in: 1...badge.maxAwards)
                    .labelsHidden()
                }
            }

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .brandGold : Color(.tertiaryLabel))
                .font(.system(size: 22))
        }
        .contentShape(Rectangle())
        .onTapGesture { vm.toggleBadge(badge) }
        .padding(.vertical, 4)
    }
}
