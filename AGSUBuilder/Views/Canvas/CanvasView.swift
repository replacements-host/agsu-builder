import SwiftUI

/// The interactive coat canvas — the core screen of the app.
///
/// **Layout (top to bottom):**
/// 1. **Soldier summary bar** — grade, branch, component, item count.
/// 2. **Canvas** — `CoatLayerView` + `InsigniaLayerView` + `MeasurementOverlayView`,
///    combined in a `ZStack` inside a `GeometryReader`.
/// 3. **Zoom preset strip** — `ZoomPresetView` for jumping between canvas zones.
/// 4. **Action buttons** — ADJUST (→ `AdjustModeView`) and EXPORT (→ `ExportView`).
///
/// **Interaction model:**
/// - `DragGesture(minimumDistance: 0)` fires on finger-up, sending the location to
///   `CanvasViewModel.handleTap(at:in:)`. If a nearby `PlacedItem` is found, it is
///   selected and `RegulationSheetView` is presented as a `.medium` detent sheet.
/// - `MagnificationGesture` adjusts `vm.zoomScale` between 0.5× and 5.0×.
/// - The toolbar "REGS" button toggles the measurement callout overlay.
struct CanvasView: View {

    let soldier: Soldier
    let items:   [UniformItem]

    @StateObject private var vm: CanvasViewModel
    @EnvironmentObject private var navCoordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var showRegulationSheet = false
    @State private var showAdjustMode      = false
    @State private var showExport          = false
    /// Live magnification factor during an active pinch gesture.
    /// Committed into `vm.zoomScale` on gesture end.
    @State private var magnification: CGFloat = 1.0
    @State private var showMeasurements    = false

    init(soldier: Soldier, items: [UniformItem]) {
        self.soldier = soldier
        self.items   = items
        _vm = StateObject(wrappedValue: CanvasViewModel(soldier: soldier, items: items))
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Soldier summary bar ────────────────────────────────────────────
            HStack {
                Text("\(soldier.grade.uppercased()) · \(soldier.branch.capitalized) · \(soldier.component.rawValue.uppercased())")
                    .font(AppFont.semiBold(13))
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text("\(vm.placedItems.count) item\(vm.placedItems.count == 1 ? "" : "s")")
                    .font(AppFont.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color(.secondarySystemBackground))

            // ── Main canvas ────────────────────────────────────────────────────
            GeometryReader { geo in
                let canvasSize = CGSize(width: geo.size.width, height: geo.size.height)

                ZStack {
                    CoatLayerView(geometry: soldier.coatVariant.geometry)

                    InsigniaLayerView(
                        placedItems:    vm.placedItems,
                        selectedItemID: vm.selectedPlacedItem?.id,
                        canvasSize:     canvasSize
                    )

                    MeasurementOverlayView(
                        placedItems:  vm.placedItems,
                        selectedItem: vm.selectedPlacedItem,
                        canvasSize:   canvasSize,
                        isVisible:    showMeasurements
                    )
                }
                .scaleEffect(vm.zoomScale * magnification)
                .offset(vm.zoomOffset)
                .contentShape(Rectangle())
                // Tap detection: DragGesture(minimumDistance: 0) gives a precise location
                // on finger-up, unlike TapGesture which only fires at the gesture's center.
                .gesture(
                    TapGesture()
                        .onEnded { }
                        .simultaneously(with:
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    vm.handleTap(at: value.location, in: canvasSize)
                                    if vm.selectedPlacedItem != nil {
                                        showRegulationSheet = true
                                    }
                                }
                        )
                )
                // Pinch-to-zoom: multiply live magnification against committed scale
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in magnification = value }
                        .onEnded { _ in
                            vm.zoomScale = max(0.5, min(vm.zoomScale * magnification, 5.0))
                            magnification = 1.0
                        }
                )
            }
            .clipped()

            // ── Zoom preset strip ──────────────────────────────────────────────
            ZoomPresetView(currentZone: vm.zoomZone, onSelect: { vm.zoomTo($0) })

            // ── Action buttons ─────────────────────────────────────────────────
            HStack(spacing: Spacing.md) {
                Button(action: { showAdjustMode = true }) {
                    Label("ADJUST", systemImage: "slider.horizontal.3")
                        .font(AppFont.buttonLabel)
                        .foregroundColor(Color(.label))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(Radius.md)
                }

                Button(action: { showExport = true }) {
                    Label("EXPORT", systemImage: "square.and.arrow.up")
                        .font(AppFont.buttonLabel)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.brandGold)
                        .cornerRadius(Radius.md)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)
        }
        .navigationTitle("Your AGSU")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if navCoordinator.shouldReturnToHome { dismiss() } }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("REGS") { showMeasurements.toggle() }
                    .font(AppFont.bodyPrimary)
                    .foregroundColor(.brandGold)
            }
        }
        .sheet(isPresented: $showRegulationSheet) {
            if let selected = vm.selectedPlacedItem {
                RegulationSheetView(
                    item:        selected,
                    isPresented: $showRegulationSheet,
                    onAdjust:    { showAdjustMode = true }
                )
            }
        }
        .navigationDestination(isPresented: $showAdjustMode) {
            AdjustModeView(vm: vm)
        }
        .navigationDestination(isPresented: $showExport) {
            ExportView(vm: vm)
        }
    }
}

struct CanvasView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CanvasView(soldier: .default, items: [])
        }
    }
}
