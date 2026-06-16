import SwiftUI

/// App launch screen.
///
/// Shows the app wordmark ("ARMY UNIFORM BUILDER · AGSU") and two navigation buttons:
/// - **BUILD MY UNIFORM** → `ProfileSetupView` (starts a new uniform from scratch)
/// - **SAVED UNIFORMS** → `SavedUniformsView` (browses previously saved uniforms)
///
/// A fine-print citation at the bottom credits DA PAM 670-1. The navigation bar is
/// hidden so the wordmark fills the full screen.
struct HomeView: View {

    @EnvironmentObject private var navCoordinator: NavigationCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Spacer()

                    // App wordmark
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

                    // Primary actions
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

                    // Regulation attribution
                    Text("Placement computed from DA PAM 670-1 · 26 Jan 2021")
                        .font(AppFont.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, Spacing.lg)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onAppear { navCoordinator.shouldReturnToHome = false }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
