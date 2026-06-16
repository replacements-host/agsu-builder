import SwiftUI
import SwiftData

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
