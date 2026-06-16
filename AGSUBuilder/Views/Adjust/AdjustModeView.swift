import SwiftUI

/// Manual position-correction screen for individual placed items.
///
/// The user selects an item by tapping the embedded mini-canvas, then uses the
/// four directional arrow buttons to nudge it in 1/16", 1/8", or 1/4" increments.
/// A context-sensitive ribbon rack configuration panel appears when any ribbon
/// item is selected, enabling live changes to ribbons-per-row, row spacing,
/// top-row alignment, and Group 3 badge position.
///
/// When the adjusted position exceeds the gender-appropriate out-of-policy threshold
/// (1/8" male, 1/4" female) an amber warning banner is displayed at the top of the screen.
///
/// "Reset to policy" clears any override and snaps the item back to its
/// regulation-derived anchor point.
struct AdjustModeView: View {

    @ObservedObject var vm: CanvasViewModel
    @Environment(\.dismiss) private var dismiss

    /// Currently selected snap grid increment for directional nudge buttons.
    @State private var snapIncrement: SnapIncrement = .eighthInch

    // MARK: - SnapIncrement

    /// Directional nudge step sizes available in the segmented control.
    enum SnapIncrement: String, CaseIterable {
        case sixteenthInch = "1/16\""
        case eighthInch    = "1/8\""
        case quarterInch   = "1/4\""

        var inches: CGFloat {
            switch self {
            case .sixteenthInch: return 1.0 / 16.0
            case .eighthInch:    return 1.0 /  8.0
            case .quarterInch:   return 1.0 /  4.0
            }
        }
    }

    // MARK: - Convenience

    private var selectedItem: PlacedItem? { vm.selectedPlacedItem }

    /// `true` when a ribbon is selected — shows the ribbon rack configuration panel.
    private var isRibbonRackSelected: Bool { selectedItem?.item.category == .ribbon }

    // MARK: - Body

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

            // Mini canvas (tap to select items)
            GeometryReader { geo in
                ZStack {
                    CoatLayerView(geometry: vm.soldier.coatVariant.geometry)
                    InsigniaLayerView(
                        placedItems:    vm.placedItems,
                        selectedItemID: vm.selectedPlacedItem?.id,
                        canvasSize:     geo.size
                    )
                }
            }
            .clipped()

            // Ribbon rack options panel (visible only when a ribbon is selected)
            if isRibbonRackSelected {
                ribbonConfigPanel
            }

            // Selected item label + reset button
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
                    Button("Reset to policy") { vm.resetToPolicy(id: item.id) }
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

            // Snap increment selector
            HStack {
                Text("SNAP:")
                    .font(AppFont.sectionHeader)
                    .foregroundColor(Color(.secondaryLabel))
                Picker("Snap", selection: $snapIncrement) {
                    ForEach(SnapIncrement.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .font(AppFont.caption)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            // Directional arrow buttons
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

    // MARK: - Ribbon Config Panel

    /// Live-updating pickers for ribbon rack configuration options.
    /// Each picker calls `vm.updateConfiguration(_:)` which immediately reruns the engine.
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
                        set: { newVal in
                            vm.updateConfiguration(UniformConfiguration(
                                ribbonsPerRow:            newVal,
                                ribbonRowSpacing:         vm.configuration.ribbonRowSpacing,
                                ribbonTopRowAlignment:    vm.configuration.ribbonTopRowAlignment,
                                badgeGroupThreePosition:  vm.configuration.badgeGroupThreePosition
                            ))
                        }
                    )) {
                        Text("3").tag(3)
                        Text("4").tag(4)
                    }
                    .pickerStyle(.segmented)
                }

                configRow("Row spacing") {
                    Picker("", selection: Binding(
                        get: { vm.configuration.ribbonRowSpacing },
                        set: { newVal in
                            vm.updateConfiguration(UniformConfiguration(
                                ribbonsPerRow:            vm.configuration.ribbonsPerRow,
                                ribbonRowSpacing:         newVal,
                                ribbonTopRowAlignment:    vm.configuration.ribbonTopRowAlignment,
                                badgeGroupThreePosition:  vm.configuration.badgeGroupThreePosition
                            ))
                        }
                    )) {
                        Text("None").tag("none")
                        Text("1/8\"").tag("eighth_inch")
                    }
                    .pickerStyle(.segmented)
                }

                configRow("Top row") {
                    Picker("", selection: Binding(
                        get: { vm.configuration.ribbonTopRowAlignment },
                        set: { newVal in
                            vm.updateConfiguration(UniformConfiguration(
                                ribbonsPerRow:            vm.configuration.ribbonsPerRow,
                                ribbonRowSpacing:         vm.configuration.ribbonRowSpacing,
                                ribbonTopRowAlignment:    newVal,
                                badgeGroupThreePosition:  vm.configuration.badgeGroupThreePosition
                            ))
                        }
                    )) {
                        Text("Centered").tag("centered")
                        Text("Left").tag("left")
                    }
                    .pickerStyle(.segmented)
                }

                configRow("Group 3 badge") {
                    Picker("", selection: Binding(
                        get: { vm.configuration.badgeGroupThreePosition },
                        set: { newVal in
                            vm.updateConfiguration(UniformConfiguration(
                                ribbonsPerRow:            vm.configuration.ribbonsPerRow,
                                ribbonRowSpacing:         vm.configuration.ribbonRowSpacing,
                                ribbonTopRowAlignment:    vm.configuration.ribbonTopRowAlignment,
                                badgeGroupThreePosition:  newVal
                            ))
                        }
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

    /// A labeled row containing an arbitrary picker or control.
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

    // MARK: - Directional Controls

    /// `true` when nudging in `delta` direction would keep the item within the 0–1 canvas bounds.
    /// Also returns `false` when no item is selected, which disables all four arrow buttons.
    private func canNudge(_ delta: CGSize) -> Bool {
        guard let item = selectedItem else { return false }
        let snapUnit   = snapIncrement.inches * vm.soldier.coatVariant.geometry.normalizedUnitsPerInch
        let currentPos = item.adjustedPosition ?? item.regulationPosition
        let newX = currentPos.x + delta.width  * snapUnit
        let newY = currentPos.y + delta.height * snapUnit
        return (0...1).contains(newX) && (0...1).contains(newY)
    }

    /// Up / left / right / down arrow buttons arranged in a cross pattern.
    @ViewBuilder
    private var directionalControls: some View {
        VStack(spacing: Spacing.xs) {
            directionButton(systemName: "arrow.up",    delta: CGSize(width:  0, height: -1))
            HStack(spacing: Spacing.xl) {
                directionButton(systemName: "arrow.left",  delta: CGSize(width: -1, height:  0))
                directionButton(systemName: "arrow.right", delta: CGSize(width:  1, height:  0))
            }
            directionButton(systemName: "arrow.down",  delta: CGSize(width:  0, height:  1))
        }
    }

    /// A single arrow button that calls `vm.moveItem(id:by:snapInches:)`.
    /// Greyed out when no item is selected or when the move would exceed the canvas boundary.
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
        .disabled(!canNudge(delta))
    }
}
