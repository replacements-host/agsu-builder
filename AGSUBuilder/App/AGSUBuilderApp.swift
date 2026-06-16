import SwiftUI

/// App entry point for Army Uniform Builder: AGSU.
///
/// **Startup sequence:**
/// 1. `HomeView` is presented as the root view.
/// 2. `DataLoader.shared.loadAll()` decodes all bundled JSON award files on first appear.
///    This is synchronous and completes in <100 ms on a warm device.
/// 3. A single `SavedUniformsViewModel` is created here and injected as an
///    `environmentObject` so that both `SavedUniformsView` and `ExportView`
///    share the same in-memory store and on-disk JSON file.
@main
struct AGSUBuilderApp: App {

    @StateObject private var savedVM = SavedUniformsViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear { DataLoader.shared.loadAll() }
                .environmentObject(savedVM)
        }
    }
}
