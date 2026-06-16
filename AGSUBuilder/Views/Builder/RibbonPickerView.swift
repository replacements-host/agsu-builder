import SwiftUI

struct RibbonPickerView: View {
    @ObservedObject var vm: InsigniaPickerViewModel
    @State private var searchText = ""

    private var filteredRibbons: [RibbonRecord] {
        let all = DataLoader.shared.ribbons(for: vm.soldier)
        if searchText.isEmpty { return all.sorted { $0.precedence < $1.precedence } }
        return all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.precedence < $1.precedence }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Order is auto-sorted by precedence")
                .font(AppFont.caption)
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.vertical, Spacing.sm)

            SearchBar(text: $searchText, placeholder: "Search ribbons...")

            List(filteredRibbons) { ribbon in
                RibbonRow(ribbon: ribbon, vm: vm)
                    .listRowBackground(Color(.secondarySystemBackground))
                    .listRowSeparatorTint(Color(.separator))
            }
            .listStyle(.plain)
        }
    }
}

struct RibbonRow: View {
    let ribbon: RibbonRecord
    @ObservedObject var vm: InsigniaPickerViewModel
    @State private var count: Int = 1

    var isSelected: Bool { vm.isSelected(ribbon) }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Color swatch placeholder
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.brandGold.opacity(0.3))
                .overlay(
                    Image(ribbon.imageAsset)
                        .resizable()
                        .scaledToFit()
                )
                .frame(width: 44, height: 14)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(.separator), lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 2) {
                Text(ribbon.name)
                    .font(AppFont.bodyPrimary)
                    .foregroundColor(Color(.label))
                Text(ribbon.shortName)
                    .font(AppFont.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            if isSelected {
                Stepper("\(vm.awardCount(for: ribbon))×", value: Binding(
                    get: { vm.awardCount(for: ribbon) },
                    set: { vm.setAwardCount($0, for: ribbon) }
                ), in: 1...9)
                .labelsHidden()
                .font(AppFont.bodySecondary)
            }

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .brandGold : Color(.tertiaryLabel))
                .font(.system(size: 22))
                .onTapGesture { vm.toggleRibbon(ribbon) }
        }
        .contentShape(Rectangle())
        .onTapGesture { vm.toggleRibbon(ribbon) }
        .padding(.vertical, 4)
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(.tertiaryLabel))
            TextField(placeholder, text: $text)
                .font(AppFont.bodyPrimary)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Radius.sm)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}
