import SwiftUI

/// Renders the coat silhouette image for the current `CoatVariant`.
///
/// If the named asset is found in the catalog (`Assets.xcassets/Coat/`), it is
/// displayed scaled to fit. When the asset is missing — as is the case with the
/// placeholder catalog — a gray `RoundedRectangle` with a shirt icon and label
/// is shown instead so the canvas remains usable without real photography.
///
/// **To replace placeholders:** Add the four `fig14_x_*.png` images (≥300 DPI,
/// portrait orientation) to `Assets.xcassets/Coat/` matching the asset names
/// returned by `CoatVariant.assetName`.
struct CoatLayerView: View {

    /// Which of the four AGSU coat silhouettes to display.
    let coatVariant: CoatVariant

    var body: some View {
        GeometryReader { geo in
            Group {
                if let img = UIImage(named: coatVariant.assetName) {
                    // Real coat photograph found in the asset catalog
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                } else {
                    // Fallback: gray placeholder rectangle with identifying label
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray4))
                        VStack(spacing: 8) {
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color(.systemGray2))
                            Text(coatVariant.displayLabel.uppercased())
                                .font(AppFont.bold(14))
                                .foregroundColor(Color(.systemGray))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview {
    CoatLayerView(coatVariant: .enlistedMale)
        .frame(width: 300, height: 450)
}
