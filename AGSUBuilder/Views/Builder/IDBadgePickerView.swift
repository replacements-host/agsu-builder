import SwiftUI

/// Picker for Identification Badges (DA PAM 670-1, para 22-17).
///
/// Shows all ID badges eligible for the soldier's component. The pocket side
/// ("Left" or "Right") is displayed as a subtitle — CSIB always goes on the right pocket.
/// Selection is capped at **two badges** (one per pocket side) enforced by
/// `InsigniaPickerViewModel.toggleIDBadge(_:)`.
struct IDBadgePickerView: View {
    @ObservedObject var vm: InsigniaPickerViewModel

    private var eligibleBadges: [IDBadgeRecord] {
        DataLoader.shared.idBadges(for: vm.soldier)
    }

    var body: some View {
        List(eligibleBadges) { badge in
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
                    Text("Pocket: \(badge.pocketSide.capitalized)")
                        .font(AppFont.caption)
                        .foregroundColor(Color(.secondaryLabel))
                    Text(badge.regulationRef)
                        .font(AppFont.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }

                Spacer()

                Image(systemName: vm.isSelected(badge) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(vm.isSelected(badge) ? .brandGold : Color(.tertiaryLabel))
                    .font(.system(size: 22))
            }
            .contentShape(Rectangle())
            .onTapGesture { vm.toggleIDBadge(badge) }
            .listRowBackground(Color(.secondarySystemBackground))
        }
        .listStyle(.plain)
        .overlay(
            Group {
                if eligibleBadges.isEmpty {
                    Text("No identification badges eligible for your branch and component.")
                        .font(AppFont.bodySecondary)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        )
    }
}
