import SwiftUI

struct TabPickerView: View {
    @ObservedObject var vm: InsigniaPickerViewModel

    private var tabs: [TabRecord] { DataLoader.shared.tabs }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.brandGold)
                Text("Tabs are sewn on the coat above your unit patch")
                    .font(AppFont.bodySecondary)
                    .foregroundColor(Color(.secondaryLabel))
            }
            .padding(Spacing.md)
            .background(Color.brandGold.opacity(0.08))

            List(tabs.sorted { $0.stackOrder < $1.stackOrder }) { tab in
                HStack(spacing: Spacing.md) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(tab.imageAsset)
                                .resizable()
                                .scaledToFit()
                                .padding(4)
                        )
                        .frame(width: 60, height: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tab.name)
                            .font(AppFont.bodyPrimary)
                            .foregroundColor(Color(.label))
                        Text(tab.regulationRef)
                            .font(AppFont.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                    }

                    Spacer()

                    Image(systemName: vm.isSelected(tab) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(vm.isSelected(tab) ? .brandGold : Color(.tertiaryLabel))
                        .font(.system(size: 22))
                }
                .contentShape(Rectangle())
                .onTapGesture { vm.toggleTab(tab) }
                .listRowBackground(Color(.secondarySystemBackground))
            }
            .listStyle(.plain)
        }
    }
}
