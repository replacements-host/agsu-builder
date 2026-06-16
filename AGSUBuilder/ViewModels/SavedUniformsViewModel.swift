import SwiftUI

/// Manages the persisted list of saved uniforms.
///
/// Uniforms are stored as a JSON-encoded array in the app's Documents directory
/// (`saved_uniforms.json`). The file is read once on init and written atomically
/// after every mutation. File size is negligible — a fully-loaded uniform is a
/// few kilobytes — so all I/O is synchronous on the main actor.
///
/// Inject this object at the app level via `.environmentObject(savedVM)` so that
/// both `SavedUniformsView` and `ExportView` share the same store instance.
@MainActor
class SavedUniformsViewModel: ObservableObject {

    /// Current list of saved uniforms, most-recently-updated first.
    @Published var uniforms: [SavedUniform] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("saved_uniforms.json")
    }()

    init() {
        loadFromDisk()
    }

    // MARK: - CRUD

    /// Removes the given uniform from the list and saves to disk.
    func delete(_ uniform: SavedUniform) {
        uniforms.removeAll { $0.id == uniform.id }
        saveToDisk()
    }

    /// Renames the given uniform, timestamps the update, and saves to disk.
    func rename(_ uniform: SavedUniform, to name: String) {
        guard let idx = uniforms.firstIndex(where: { $0.id == uniform.id }) else { return }
        uniforms[idx].name      = name
        uniforms[idx].updatedAt = Date()
        saveToDisk()
    }

    /// Serializes the current canvas state into a new `SavedUniform` and persists it.
    ///
    /// Item list is encoded as a JSON array of `{id, awardCount, devices}` dictionaries.
    /// Adjustment overrides are not saved in v1 (stored as empty `{}`).
    func save(canvasVM: CanvasViewModel, name: String) {
        var uniform = SavedUniform(name: name, soldier: canvasVM.soldier)
        uniform.ribbonsPerRow           = canvasVM.configuration.ribbonsPerRow
        uniform.ribbonRowSpacing        = canvasVM.configuration.ribbonRowSpacing
        uniform.ribbonTopRowAlignment   = canvasVM.configuration.ribbonTopRowAlignment
        uniform.badgeGroupThreePosition = canvasVM.configuration.badgeGroupThreePosition

        let itemDicts = canvasVM.selectedItems.map { item -> [String: Any] in
            ["id": item.id, "awardCount": item.awardCount, "devices": item.devices]
        }
        if let data = try? JSONSerialization.data(withJSONObject: itemDicts),
           let str  = String(data: data, encoding: .utf8) {
            uniform.itemsJSON = str
        }

        uniforms.insert(uniform, at: 0)
        saveToDisk()

        requestReviewIfEligible()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([SavedUniform].self, from: data) else { return }
        uniforms = decoded
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(uniforms) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Review Request

    /// Requests an App Store review at most once per year using a UserDefaults gate.
    /// The actual `SKStoreReviewController` call is a TODO pending StoreKit import.
    private func requestReviewIfEligible() {
        let key      = "lastReviewRequestDate"
        let calendar = Calendar.current
        if let last = UserDefaults.standard.object(forKey: key) as? Date,
           let diff = calendar.dateComponents([.day], from: last, to: Date()).day,
           diff < 365 { return }
        UserDefaults.standard.set(Date(), forKey: key)
        // TODO: import StoreKit; call SKStoreReviewController.requestReview(in:windowScene)
    }
}
