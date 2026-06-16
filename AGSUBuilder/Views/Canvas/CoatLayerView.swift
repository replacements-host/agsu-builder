import SwiftUI

struct CoatLayerView: View {
    let coatVariant: CoatVariant

    var body: some View {
        GeometryReader { geo in
            Group {
                if let img = UIImage(named: coatVariant.assetName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                } else {
                    // Placeholder gray rectangle with label (used until real coat images are provided)
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
