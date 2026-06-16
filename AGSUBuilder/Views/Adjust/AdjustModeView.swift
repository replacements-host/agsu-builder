import SwiftUI

struct AdjustModeView: View {
    @ObservedObject var vm: CanvasViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var snapIncrement: SnapIncrement = .eighthInch

    enum SnapIncrement: String, CaseIterable {
        case sixteenthInch = "1/16\""
        case eighthInch = "1/8\""
        case quarterInch = "1/4\""

        var inches: CGFloat {
            switch self {
            case .sixteenthInch: return 1.0/16.0
            case .eighthInch:    return 1.0/8.0
            case .quarterInch:   return 1.0/4.0
            }
        }
    }

    private var selectedItem: PlacedItem? { vm.selectedPlacedItem }
    private var isRibbonRackSelected: Bool {
        selectedItem?.item.category == .ribbon
    }

    var body: some View {
        VStack(spacing: 0) {

            // Out-of-policy warning banner
            if let item = selectedItem, item.isOutOfPolicy {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.brandAmber)
                    Text(item.soldier.gender == .female
                        ? "Outside body-shape adjustment range"
                        : "Outside prescribed position — DA PAM 670-1")
                        .font(AppFont.semiBold(13))
                        .foregroundColor(.brandAmber)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.sm)
                .background(Color.brandAmber.opacity(0.12))
            }

            // Canvas
            GeometryReader { geo in
                let canvasSize = geo.size
                ZStack {
                    CoatLayerView(coatVariant: vm.soldier.coatVariant)
                    InsigniaLayerView(
                        placedItems: vm.placedItems,
                        selectedItemID: vm.selectedPlacedItem?.id,
                        canvasSize: canvasSize
                    )
                }
            }
            .clipped()

            // Configuration panel for ribbon rack
            if isRibbonRackSelected {
                ribbonConfigPanel
            }

            // Selected item label + reset
            if let item = selectedItem {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SELECTED")
                            .font(AppFont.sectionHeader)
                            .foregroundColor(Color(.tertiaryLabel))
                        Text(item.item.id.replacingOccurrences(of: "_", with: " ").uppercased())
                            .font(AppFont.semiBold(15))
                            .foregroundColor(Color(.label))
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("Reset to policy") {
                        vm.resetToPolicy(id: item.id)
                    }
                    .font(AppFont.bodySecondary)
                    .foregroundColor(.brandGold)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
            } else {
                Text("Tap an item on the coat to select it")
                    .font(AppFont.bodySecondary)
                    .foregroundColor(Color(.tertiaryLabel))
                    .padding(.top, Spacing.sm)
            }

            // Snap increment picker
            HStack {
                Text("SNAP:")
                    .font(AppFont.sectionHeader)
                    .foregroundColor(Color(.secondaryLabel))
                Picker("Snap", selection: $snapIncrement) {
                    ForEach(SnapIncrement.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .font(AppFont.caption)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            // Directional controls
            directionalControls
                .padding(Spacing.md)
        }
        .navigationTitle("Adjust")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .font(AppFont.buttonLabel)
                    .foregroundColor(.brandGold)
            }
        }
    }

    @ViewBuilder
    private var ribbonConfigPanel: some View {
        VStack(spacing: Spacing.sm) {
            Divider()
            Text("RIBBON RACK CONFIGURATION")
                .font(AppFont.sectionHeader)
                .foregroundColor(Color(.secondaryLabel))

            Group {
                configRow("Ribbons per row") {
                    Picker("", selection: Binding(
                        get: { vm.configuration.ribbonsPerRow },
                        set: { vm.updateConfiguration(UniformConfiguration(
                            ribbonsPerRow: $0,
                            ribbonRowSpacing: vm.configuration.ribbonRowSpacing,
                            ribbonTopRowAlignment: vm.configuration.ribbonTopRowAlignment,
                            badgeGroupThreePosition: vm.configuration.badgeGroupThreePosition
                        )) }
                    )) {
                        Text("3").tag(3)
                        Text("4").tag(4)
                    }
                    .pickerStyle(.segmented)
                }

                configRow("Row spacing") {
                    Picker("", selection: Binding(
                        get: { vm.configuration.ribbonRowSpacing },
                        set: { vm.updateConfiguration(UniformConfiguration(
                            ribbonsPerRow: vm.configuration.ribbonsPerRow,
                            ribbonRowSpacing: $0,
                            ribbonTopRowAlignment: vm.configuration.ribbonTopRowAlignment,
                            badgeGroupThreePosition: vm.configuration.badgeGroupThreePosition
                        )) }
                    )) {
                        Text("None").tag("none")
                        Text("1/8\"").tag("eighth_inch")
                    }
                    .pickerStyle(.segmented)
                }

                configRow("Top row") {
                    Picker("", selection: Binding(
                        get: { vm.configuration.ribbonTopRowAlignment },
                        set: { vm.updateConfiguration(UniformConfiguration(
                            ribbonsPerRow: vm.configuration.ribbonsPerRow,
                            ribbonRowSpacing: vm.configuration.ribbonRowSpacing,
                            ribbonTopRowAlignment: $0,
                            badgeGroupThreePosition: vm.configuration.badgeGroupThreePosition
                        )) }
                    )) {
                        Text("Centered").tag("centered")
                        Text("Left").tag("left")
                    }
                    .pickerStyle(.segmented)
                }

                configRow("Group 3 badge") {
                    Picker("", selection: Binding(
                        get: { vm.configuration.badgeGroupThreePosition },
                        set: { vm.updateConfiguration(UniformConfiguration(
                            ribbonsPerRow: vm.configuration.ribbonsPerRow,
                            ribbonRowSpacing: vm.configuration.ribbonRowSpacing,
                            ribbonTopRowAlignment: vm.configuration.ribbonTopRowAlignment,
                            badgeGroupThreePosition: $0
                        )) }
                    )) {
                        Text("Above").tag("above")
                        Text("Below").tag("below")
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color(.secondarySystemBackground))
    }

    @ViewBuilder
    private func configRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(AppFont.regular(13))
                .foregroundColor(Color(.secondaryLabel))
                .frame(width: 110, alignment: .leading)
            content()
        }
    }

    @ViewBuilder
    private var directionalControls: some View {
        VStack(spacing: Spacing.xs) {
            directionButton(systemName: "arrow.up", delta: CGSize(width: 0, height: -1))
            HStack(spacing: Spacing.xl) {
                directionButton(systemName: "arrow.left", delta: CGSize(width: -1, height: 0))
                directionButton(systemName: "arrow.right", delta: CGSize(width: 1, height: 0))
            }
            directionButton(systemName: "arrow.down", delta: CGSize(width: 0, height: 1))
        }
    }

    @ViewBuilder
    private func directionButton(systemName: String, delta: CGSize) -> some View {
        Button(action: {
            guard let id = vm.selectedPlacedItem?.id else { return }
            vm.moveItem(id: id, by: delta, snapInches: snapIncrement.inches)
        }) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(Radius.sm)
        }
        .foregroundColor(Color(.label))
        .disabled(vm.selectedPlacedItem == nil)
    }
}
