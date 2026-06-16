import SwiftUI

/// Step 5 of the builder flow: collects service stripe and overseas bar counts.
///
/// **Service stripes** (left sleeve, DA PAM 670-1, para 21-28):
/// Each gold stripe represents 3 years of active federal service.
/// The stepper allows 0–20 stripes. A visual preview of gold bars is shown.
///
/// **Overseas service bars** (right sleeve, DA PAM 670-1, para 21-29):
/// Each bar represents one 6-month tour in a hostile fire / imminent danger pay area.
/// The stepper allows 0–20 bars.
///
/// Both counts are stored in `InsigniaPickerViewModel` and emitted as
/// `UniformItem` values in `allSelectedItems` with `.serviceStripe(count:)` and
/// `.overseasBar(count:)` categories.
struct ServiceStripeView: View {
    @ObservedObject var vm: InsigniaPickerViewModel

    var body: some View {
        Form {
            Section {
                Stepper("Service Stripes: \(vm.serviceStripeCount)", value: $vm.serviceStripeCount, in: 0...20)
                    .font(AppFont.bodyPrimary)

                Text("Each stripe represents 3 years of active federal service. Worn on the left sleeve.")
                    .font(AppFont.caption)
                    .foregroundColor(Color(.secondaryLabel))
                    .listRowBackground(Color.clear)

                // Visual preview of stripes
                if vm.serviceStripeCount > 0 {
                    HStack(spacing: 3) {
                        ForEach(0..<min(vm.serviceStripeCount, 20), id: \.self) { _ in
                            Rectangle()
                                .fill(Color.brandGold)
                                .frame(width: 6, height: 30)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("SERVICE STRIPES")
                    .font(AppFont.sectionHeader)
            } footer: {
                Text("DA PAM 670-1, para 21-28")
                    .font(AppFont.caption)
                    .foregroundColor(.brandGold)
            }

            Section {
                Stepper("Overseas Service Bars: \(vm.overseasBarCount)", value: $vm.overseasBarCount, in: 0...20)
                    .font(AppFont.bodyPrimary)

                Text("Each bar represents 6 months of overseas service in a hostile fire/imminent danger pay area. Worn on the right sleeve.")
                    .font(AppFont.caption)
                    .foregroundColor(Color(.secondaryLabel))
                    .listRowBackground(Color.clear)

                // Visual preview of bars
                if vm.overseasBarCount > 0 {
                    HStack(spacing: 3) {
                        ForEach(0..<min(vm.overseasBarCount, 20), id: \.self) { _ in
                            Rectangle()
                                .fill(Color(.systemOrange))
                                .frame(width: 6, height: 20)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("OVERSEAS SERVICE BARS")
                    .font(AppFont.sectionHeader)
            } footer: {
                Text("DA PAM 670-1, para 21-29")
                    .font(AppFont.caption)
                    .foregroundColor(.brandGold)
            }
        }
        .scrollContentBackground(.hidden)
    }
}
