import SwiftUI
import SwiftData

/// App entry point for Army Uniform Builder: AGSU.
///
/// **Startup sequence:**
/// 1. `HomeView` is presented inside a `NavigationStack`-free root (navigation is
///    initiated inside `HomeView` itself).
/// 2. `DataLoader.shared.loadAll()` decodes all bundled JSON award files on first appear.
///    This is synchronous and completes in <100 ms on a warm device; if it ever grows
///    large, move it to a background task.
/// 3. The `SwiftData` model container is configured for `SavedUniform` and injected
///    into the environment so any descendant view can access `@Environment(\.modelContext)`.
@main
struct AGSUBuilderApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear { DataLoader.shared.loadAll() }
        }
        .modelContainer(for: SavedUniform.self)
    }
}
