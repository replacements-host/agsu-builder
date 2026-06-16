import SwiftUI

struct CanvasView: View {
    let soldier: Soldier
    let items: [UniformItem]

    @StateObject private var vm: CanvasViewModel
    @State private var showRegulationSheet = false
    @State private var showAdjustMode = false
    @State private var showExport = false
    @State private var magnification: CGFloat = 1.0
    @State private var showMeasurements = false

    init(soldier: Soldier, items: [UniformItem]) {
        self.soldier = soldier
        self.items = items
        _vm = StateObject(wrappedValue: CanvasViewModel(soldier: soldier, items: items))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Soldier summary bar
            HStack {
                Text("\(soldier.grade.uppercased()) · \(soldier.branch.capitalized) · \(soldier.component.rawValue.uppercased())")
                    .font(AppFont.semiBold(13))
                    .foregroundColor(Color(.secondaryLabel))
                Spacer()
                Text("\(vm.placedItems.count) item\(vm.placedItems.count == 1 ? "" : "s")")
                    .font(AppFont.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color(.secondarySystemBackground))

            // Main canvas
            GeometryReader { geo in
                let canvasSize = CGSize(
                    width: geo.size.width,
                    height: geo.size.height
                )

                ZStack {
                    CoatLayerView(coatVariant: soldier.coatVariant)

                    InsigniaLayerView(
                        placedItems: vm.placedItems,
                        selectedItemID: vm.selectedPlacedItem?.id,
                        canvasSize: canvasSize
                    )

                    MeasurementOverlayView(
                        placedItems: vm.placedItems,
                        selectedItem: vm.selectedPlacedItem,
                        canvasSize: canvasSize,
                        isVisible: showMeasurements
                    )
                }
                .scaleEffect(vm.zoomScale * magnification)
                .offset(vm.zoomOffset)
                .contentShape(Rectangle())
                .gesture(
                    TapGesture()
                        .onEnded {
                            // Tap detection handled via simultaneous gesture below
                        }
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
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in magnification = value }
                        .onEnded { _ in
                            vm.zoomScale *= magnification
                            vm.zoomScale = max(0.5, min(vm.zoomScale, 5.0))
                            magnification = 1.0
                        }
                )
            }
            .clipped()

            // Zoom presets
            ZoomPresetView(currentZone: vm.zoomZone, onSelect: { vm.zoomTo($0) })

            // Action buttons
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("REGS") {
                    showMeasurements.toggle()
                }
                .font(AppFont.bodyPrimary)
                .foregroundColor(.brandGold)
            }
        }
        .sheet(isPresented: $showRegulationSheet) {
            if let selected = vm.selectedPlacedItem {
                RegulationSheetView(
                    item: selected,
                    isPresented: $showRegulationSheet,
                    onAdjust: { showAdjustMode = true }
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

#Preview {
    NavigationStack {
        CanvasView(soldier: .default, items: [])
    }
}
