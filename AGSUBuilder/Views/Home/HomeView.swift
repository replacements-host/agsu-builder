import SwiftUI

struct HomeView: View {
    @State private var navigateToProfile = false
    @State private var navigateToSaved = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Spacer()

                    VStack(spacing: Spacing.sm) {
                        Text("ARMY UNIFORM BUILDER")
                            .font(AppFont.bold(32))
                            .foregroundColor(.brandGold)
                            .multilineTextAlignment(.center)

                        Text("AGSU")
                            .font(AppFont.bold(28))
                            .foregroundColor(.brandGold)

                        Text("AGSU Uniform Builder")
                            .font(AppFont.light(16))
                            .foregroundColor(Color(.secondaryLabel))
                    }

                    Spacer()

                    VStack(spacing: Spacing.md) {
                        NavigationLink(destination: ProfileSetupView()) {
                            Text("BUILD MY UNIFORM")
                                .font(AppFont.buttonLabel)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.brandGold)
                                .cornerRadius(Radius.lg)
                        }

                        NavigationLink(destination: SavedUniformsView()) {
                            Text("SAVED UNIFORMS")
                                .font(AppFont.buttonLabel)
                                .foregroundColor(Color(.label))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.lg)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    Text("Placement computed from DA PAM 670-1 · 26 Jan 2021")
                        .font(AppFont.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, Spacing.lg)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    HomeView()
}
