import SwiftUI
import SwiftData

@MainActor
class SavedUniformsViewModel: ObservableObject {
    @Published var uniforms: [SavedUniform] = []

    func delete(_ uniform: SavedUniform, context: ModelContext) {
        context.delete(uniform)
        try? context.save()
    }

    func rename(_ uniform: SavedUniform, to name: String, context: ModelContext) {
        uniform.name = name
        uniform.updatedAt = Date()
        try? context.save()
    }

    func save(canvasVM: CanvasViewModel, name: String, context: ModelContext) {
        let uniform = SavedUniform(name: name, soldier: canvasVM.soldier)
        uniform.ribbonsPerRow = canvasVM.configuration.ribbonsPerRow
        uniform.ribbonRowSpacing = canvasVM.configuration.ribbonRowSpacing
        uniform.ribbonTopRowAlignment = canvasVM.configuration.ribbonTopRowAlignment
        uniform.badgeGroupThreePosition = canvasVM.configuration.badgeGroupThreePosition

        // Encode items as JSON
        let itemDicts = canvasVM.selectedItems.map { item -> [String: Any] in
            ["id": item.id, "awardCount": item.awardCount, "devices": item.devices]
        }
        if let data = try? JSONSerialization.data(withJSONObject: itemDicts),
           let str = String(data: data, encoding: .utf8) {
            uniform.itemsJSON = str
        }

        context.insert(uniform)
        try? context.save()

        requestReviewIfEligible()
    }

    private func requestReviewIfEligible() {
        let key = "lastReviewRequestDate"
        let calendar = Calendar.current
        if let last = UserDefaults.standard.object(forKey: key) as? Date,
           let diff = calendar.dateComponents([.day], from: last, to: Date()).day,
           diff < 365 { return }
        UserDefaults.standard.set(Date(), forKey: key)
        // TODO: import StoreKit and call SKStoreReviewController.requestReview
    }
}
