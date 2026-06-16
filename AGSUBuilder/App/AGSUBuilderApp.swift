import SwiftUI

/// Shared coordinator for programmatic pop-to-root navigation.
///
/// Any view that wants to participate in the "Return to Home" chain should:
/// 1. Add `@EnvironmentObject var navCoordinator: NavigationCoordinator`
/// 2. Add `@Environment(\.dismiss) private var dismiss`
/// 3. Add `.onAppear { if navCoordinator.shouldReturnToHome { dismiss() } }`
///
/// HomeView resets the flag in its own `.onAppear` so the chain stops there.
class NavigationCoordinator: ObservableObject {
    @Published var shouldReturnToHome = false
}

/// App entry point for Army Uniform Builder: AGSU.
///
/// **Startup sequence:**
/// 1. `HomeView` is presented as the root view.
/// 2. `DataLoader.shared.loadAll()` decodes all bundled JSON award files on first appear.
///    This is synchronous and completes in <100 ms on a warm device.
/// 3. A single `SavedUniformsViewModel` is created here and injected as an
///    `environmentObject` so that both `SavedUniformsView` and `ExportView`
///    share the same in-memory store and on-disk JSON file.
/// 4. A `NavigationCoordinator` is injected so any view can trigger pop-to-root.
@main
struct AGSUBuilderApp: App {

    @StateObject private var savedVM        = SavedUniformsViewModel()
    @StateObject private var navCoordinator = NavigationCoordinator()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear { DataLoader.shared.loadAll() }
                .environmentObject(savedVM)
                .environmentObject(navCoordinator)
        }
    }
}
