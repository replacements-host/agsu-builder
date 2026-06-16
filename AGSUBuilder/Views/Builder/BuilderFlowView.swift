import SwiftUI

struct BuilderFlowView: View {
    let soldier: Soldier

    @StateObject private var pickerVM: InsigniaPickerViewModel
    @State private var step = 0
    @State private var navigateToCanvas = false

    private let stepTitles = ["Ribbons", "Badges", "ID Badges", "Tabs", "Service Stripes"]

    init(soldier: Soldier) {
        self.soldier = soldier
        _pickerVM = StateObject(wrappedValue: InsigniaPickerViewModel(soldier: soldier))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 3)
                    Rectangle()
                        .fill(Color.brandGold)
                        .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(stepTitles.count), height: 3)
                        .animation(.easeInOut, value: step)
                }
            }
            .frame(height: 3)

            // Step content
            Group {
                switch step {
                case 0: RibbonPickerView(vm: pickerVM)
                case 1: BadgePickerView(vm: pickerVM)
                case 2: IDBadgePickerView(vm: pickerVM)
                case 3: TabPickerView(vm: pickerVM)
                case 4: ServiceStripeView(vm: pickerVM)
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation buttons
            HStack {
                if step > 0 {
                    Button("Back") { withAnimation { step -= 1 } }
                        .font(AppFont.buttonLabel)
                        .foregroundColor(Color(.secondaryLabel))
                }

                Spacer()

                if step < stepTitles.count - 1 {
                    Button("Next · \(stepTitles[step + 1])") {
                        withAnimation { step += 1 }
                    }
                    .font(AppFont.buttonLabel)
                    .foregroundColor(.brandGold)
                } else {
                    NavigationLink(destination: CanvasView(
                        soldier: soldier,
                        items: pickerVM.allSelectedItems
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
