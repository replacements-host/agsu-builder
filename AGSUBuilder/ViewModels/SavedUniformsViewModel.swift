import SwiftUI
import SwiftData

/// Drives the saved-uniforms list and handles persistence operations.
///
/// `@Query` in `SavedUniformsView` owns the actual fetched results. This view model
/// handles write operations (delete, rename, save) that need a `ModelContext`.
@MainActor
class SavedUniformsViewModel: ObservableObject {

    @Published var uniforms: [SavedUniform] = []

    // MARK: - CRUD

    /// Deletes the given uniform from the SwiftData store and saves immediately.
    func delete(_ uniform: SavedUniform, context: ModelContext) {
        context.delete(uniform)
        try? context.save()
    }

    /// Renames the given uniform and timestamps the update.
    func rename(_ uniform: SavedUniform, to name: String, context: ModelContext) {
        uniform.name      = name
        uniform.updatedAt = Date()
        try? context.save()
    }

    /// Serializes the current canvas state into a new `SavedUniform` and inserts it.
    ///
    /// Item list is encoded as a JSON array of `{id, awardCount, devices}` dictionaries.
    /// Adjustment overrides are not saved in v1 (stored as empty `{}`).
    func save(canvasVM: CanvasViewModel, name: String, context: ModelContext) {
        let uniform = SavedUniform(name: name, soldier: canvasVM.soldier)
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

        context.insert(uniform)
        try? context.save()

        requestReviewIfEligible()
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
