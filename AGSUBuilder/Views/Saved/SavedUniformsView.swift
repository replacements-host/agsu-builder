import SwiftUI
import SwiftData

struct SavedUniformsView: View {
    @Query(sort: \SavedUniform.updatedAt, order: .reverse) private var uniforms: [SavedUniform]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = SavedUniformsViewModel()
    @State private var renameTarget: SavedUniform? = nil
    @State private var renameText = ""
    @State private var navigateToCanvas: SavedUniform? = nil

    var body: some View {
        Group {
            if uniforms.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(uniforms) { uniform in
                        uniformRow(uniform)
                            .listRowBackground(Color(.secondarySystemBackground))
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { vm.delete(uniforms[$0], context: modelContext) }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Saved Uniforms")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Rename Uniform", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let target = renameTarget {
                    vm.rename(target, to: renameText, context: modelContext)
                }
                renameTarget = nil
            }
            Button("Cancel", role: .cancel) { renameTarget = nil }
        }
        .navigationDestination(isPresented: Binding(
            get: { navigateToCanvas != nil },
            set: { if !$0 { navigateToCanvas = nil } }
        )) {
            if let uniform = navigateToCanvas {
                CanvasView(soldier: uniform.toSoldier(), items: [])
            }
        }
    }

    @ViewBuilder
    private func uniformRow(_ uniform: SavedUniform) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(uniform.name)
                    .font(AppFont.bodyPrimary)
                    .foregroundColor(Color(.label))
                Text("\(uniform.grade) · \(uniform.branch.capitalized)")
                    .font(AppFont.bodySecondary)
                    .foregroundColor(Color(.secondaryLabel))
                Text(uniform.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(AppFont.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .contentShape(Rectangle())
        .onTapGesture { navigateToCanvas = uniform }
        .onLongPressGesture {
            renameTarget = uniform
            renameText = uniform.name
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "tshirt")
                .font(.system(size: 60))
                .foregroundColor(Color(.systemGray3))
            Text("No Saved Uniforms")
                .font(AppFont.bold(22))
                .foregroundColor(Color(.secondaryLabel))
            Text("No saved uniforms. Build your first one.")
                .font(AppFont.bodySecondary)
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            Spacer()
        }
    }
}
