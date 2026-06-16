import SwiftUI

/// Five-step wizard that walks the user through selecting all insignia for their uniform.
///
/// Steps (in order):
/// 1. **Ribbons** — `RibbonPickerView`
/// 2. **Badges** — `BadgePickerView`
/// 3. **ID Badges** — `IDBadgePickerView`
/// 4. **Tabs** — `TabPickerView`
/// 5. **Service Stripes** — `ServiceStripeView` (also collects overseas bar count)
///
/// A single `InsigniaPickerViewModel` is shared across all five steps so selections
/// persist as the user moves forward and back. On the final step, "VIEW MY UNIFORM"
/// navigates to `CanvasView` with `pickerVM.allSelectedItems`.
///
/// A gold progress bar at the top fills incrementally as the user advances through steps.
/// Each step can be skipped via the "Skip" toolbar button.
struct BuilderFlowView: View {

    let soldier: Soldier

    @EnvironmentObject private var navCoordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss

    /// Shared picker state across all five steps.
    @StateObject private var pickerVM: InsigniaPickerViewModel
    /// Current step index (0-based).
    @State private var step = 0

    private let stepTitles = ["Ribbons", "Badges", "ID Badges", "Tabs", "Service Stripes"]

    init(soldier: Soldier) {
        self.soldier = soldier
        _pickerVM = StateObject(wrappedValue: InsigniaPickerViewModel(soldier: soldier))
    }

    var body: some View {
        VStack(spacing: 0) {

            // Gold progress bar — fills proportionally as step advances
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 3)
                    Rectangle()
                        .fill(Color.brandGold)
                        .frame(
                            width: geo.size.width * CGFloat(step + 1) / CGFloat(stepTitles.count),
                            height: 3
                        )
                        .animation(.easeInOut, value: step)
                }
            }
            .frame(height: 3)

            // Step content — swapped by switching on `step`
            Group {
                switch step {
                case 0: RibbonPickerView(vm:   pickerVM)
                case 1: BadgePickerView(vm:    pickerVM)
                case 2: IDBadgePickerView(vm:  pickerVM)
                case 3: TabPickerView(vm:      pickerVM)
                case 4: ServiceStripeView(vm:  pickerVM)
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Back / Next / VIEW MY UNIFORM navigation row
            HStack {
                if step > 0 {
                    Button("Back") { withAnimation { step -= 1 } }
                        .font(AppFont.buttonLabel)
                        .foregroundColor(Color(.secondaryLabel))
                }

                Spacer()

                if step < stepTitles.count - 1 {
                    // Intermediate steps: show next step title for orientation
                    Button("Next · \(stepTitles[step + 1])") {
                        withAnimation { step += 1 }
                    }
                    .font(AppFont.buttonLabel)
                    .foregroundColor(.brandGold)
                } else {
                    // Final step: navigate to the canvas with all selections
                    NavigationLink(destination: CanvasView(
                        soldier: soldier,
                        items:   pickerVM.allSelectedItems
                    )) {
                        Text("VIEW MY UNIFORM")
                            .font(AppFont.buttonLabel)
                            .foregroundColor(.black)
                            .padding(.horizontal, Spacing.lg)
                            .frame(height: 44)
                            .background(Color.brandGold)
                            .cornerRadius(Radius.lg)
                    }
                }
            }
            .padding(Spacing.md)
        }
        .navigationTitle(stepTitles[step])
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if navCoordinator.shouldReturnToHome { dismiss() } }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if step < stepTitles.count - 1 {
                    Button("Skip") { withAnimation { step += 1 } }
                        .font(AppFont.bodyPrimary)
                        .foregroundColor(.brandGold)
                }
            }
        }
    }
}
