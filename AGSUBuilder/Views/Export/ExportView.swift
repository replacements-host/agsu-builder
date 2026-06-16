import SwiftUI
import SwiftData

/// Offers four export formats plus uniform saving to SwiftData.
///
/// **Export options:**
/// 1. **PDF Spec Sheet** — `UIGraphicsPDFRenderer` generates an 8.5×11" page with the
///    coat image and a regulation citation table.
/// 2. **Image (Front View)** — `ImageRenderer` captures the coat + insignia at 3× scale.
/// 3. **Setup Checklist** — Plain text ordered list of attachment steps.
/// 4. **Share to Unit** — Passes a `UIImage` to the iOS share sheet.
///
/// All export options funnel through `UIActivityViewController` via the `ShareSheet` wrapper.
/// Saving a uniform inserts a new `SavedUniform` into the SwiftData model context.
struct ExportView: View {

    @ObservedObject var vm: CanvasViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showShareSheet  = false
    @State private var showSaveDialog  = false
    @State private var uniformName     = ""
    @State private var shareItems: [Any] = []
    @StateObject private var savedVM = SavedUniformsViewModel()

    var body: some View {
        List {

            // ── Coat thumbnail ─────────────────────────────────────────────────
            Section {
                GeometryReader { geo in
                    ZStack {
                        CoatLayerView(coatVariant: vm.soldier.coatVariant)
                        InsigniaLayerView(
                            placedItems:    vm.placedItems,
                            selectedItemID: nil,
                            canvasSize:     geo.size
                        )
                    }
                }
                .frame(height: 200)
                .cornerRadius(Radius.md)
                .listRowInsets(EdgeInsets())
            }

            // ── Export options ─────────────────────────────────────────────────
            Section("EXPORT") {
                exportRow(icon: "doc.text.fill",
                          title: "PDF Spec Sheet",
                          subtitle: "Full measurements and regulation citations") {
                    exportPDF()
                }
                exportRow(icon: "photo.fill",
                          title: "Image (Front View)",
                          subtitle: "Clean coat image without measurement overlays") {
                    exportImage()
                }
                exportRow(icon: "list.number",
                          title: "Setup Checklist",
                          subtitle: "Step-by-step instructions for physical uniform") {
                    exportChecklist()
                }
                exportRow(icon: "square.and.arrow.up",
                          title: "Share to Unit",
                          subtitle: "Share via iOS share sheet") {
                    shareImage()
                }
            }

            // ── Save uniform ───────────────────────────────────────────────────
            Section("SAVE") {
                Button(action: { showSaveDialog = true }) {
                    Label("Save This Uniform", systemImage: "bookmark.fill")
                        .font(AppFont.bodyPrimary)
                        .foregroundColor(.brandGold)
                }
            }

            // ── Items summary table ────────────────────────────────────────────
            Section("ITEMS (\(vm.placedItems.count))") {
                ForEach(vm.placedItems) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.item.id.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(AppFont.bodyPrimary)
                            .foregroundColor(Color(.label))
                        Text(item.regulationRef)
                            .font(AppFont.caption)
                            .foregroundColor(.brandGold)
                        if let m = item.measurements.first {
                            Text("\(m.label): \(m.value)")
                                .font(AppFont.caption)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                }
            }

            // Disclaimer
            Section {
                Text("Not affiliated with or endorsed by the U.S. Army or Department of Defense. Placement information derived from publicly available Army regulations (DA PAM 670-1). Always verify against current regulations.")
                    .font(AppFont.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportPDF) {
                    Text("PDF")
                        .font(AppFont.buttonLabel)
                        .foregroundColor(.brandGold)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("Save Uniform", isPresented: $showSaveDialog) {
            TextField("Name (e.g., SGT Smith · 2026)", text: $uniformName)
            Button("Save") {
                let name = uniformName.isEmpty
                    ? "\(vm.soldier.grade) · \(Date().formatted(date: .abbreviated, time: .omitted))"
                    : uniformName
                savedVM.save(canvasVM: vm, name: name, context: modelContext)
                uniformName = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Give this uniform a name to find it later.")
        }
    }

    // MARK: - Row Builder

    /// Reusable list row with icon, title, subtitle, and chevron.
    @ViewBuilder
    private func exportRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.brandGold)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.bodyPrimary)
                        .foregroundColor(Color(.label))
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
    }

    // MARK: - Export Actions

    private func exportPDF() {
        shareItems = [generatePDF(coatImage: renderCanvasImage())]
        showShareSheet = true
    }

    private func exportImage() {
        shareItems = [renderCanvasImage()]
        showShareSheet = true
    }

    private func exportChecklist() {
        shareItems = [generateSetupChecklist()]
        showShareSheet = true
    }

    private func shareImage() {
        shareItems = [renderCanvasImage()]
        showShareSheet = true
    }

    // MARK: - Rendering

    /// Renders the coat and all placed insignia into a `UIImage` at 3× scale
    /// using SwiftUI's `ImageRenderer` (iOS 16+).
    private func renderCanvasImage() -> UIImage {
        let renderer = ImageRenderer(content:
            ZStack {
                CoatLayerView(coatVariant: vm.soldier.coatVariant)
                InsigniaLayerView(
                    placedItems:    vm.placedItems,
                    selectedItemID: nil,
                    canvasSize:     CGSize(width: 390, height: 600)
                )
            }
            .frame(width: 390, height: 600)
        )
        renderer.scale = 3.0
        return renderer.uiImage ?? UIImage()
    }

    /// Generates an 8.5×11" PDF with the coat image and an item citation table.
    private func generatePDF(coatImage: UIImage) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            let cgCtx = ctx.cgContext

            // Title
            "ARMY UNIFORM BUILDER: AGSU — Spec Sheet".draw(
                at: CGPoint(x: 36, y: 36),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.black]
            )
            "\(vm.soldier.grade) · \(vm.soldier.branch.capitalized) · \(vm.soldier.component.rawValue)".draw(
                at: CGPoint(x: 36, y: 60),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.darkGray]
            )

            // Coat image (200×300 pt at left margin)
            coatImage.draw(in: CGRect(x: 36, y: 90, width: 200, height: 300))

            // Item citation table at right
            var tableX: CGFloat = 260
            var tableY: CGFloat = 90
            let smallFont = UIFont.systemFont(ofSize: 9)
            let boldFont  = UIFont.boldSystemFont(ofSize: 9)

            "ITEM".draw(at:       CGPoint(x: tableX,       y: tableY), withAttributes: [.font: boldFont])
            "REGULATION".draw(at: CGPoint(x: tableX + 160, y: tableY), withAttributes: [.font: boldFont])
            tableY += 14
            cgCtx.setStrokeColor(UIColor.lightGray.cgColor)
            cgCtx.stroke(CGRect(x: tableX, y: tableY, width: 316, height: 0.5))
            tableY += 4

            for item in vm.placedItems where tableY < 750 {
                let name = item.item.id.replacingOccurrences(of: "_", with: " ").capitalized
                name.draw(at:            CGPoint(x: tableX,       y: tableY), withAttributes: [.font: smallFont])
                item.regulationRef.draw(at: CGPoint(x: tableX + 160, y: tableY), withAttributes: [.font: smallFont, .foregroundColor: UIColor.systemOrange])
                tableY += 12
                if let m = item.measurements.first {
                    "\(m.label): \(m.value)".draw(at: CGPoint(x: tableX + 8, y: tableY), withAttributes: [.font: smallFont, .foregroundColor: UIColor.gray])
                    tableY += 10
                }
            }

            "Not affiliated with or endorsed by the U.S. Army. DA PAM 670-1, 26 January 2021.".draw(
                at: CGPoint(x: 36, y: 760),
                withAttributes: [.font: UIFont.systemFont(ofSize: 7), .foregroundColor: UIColor.lightGray]
            )
        }
    }

    /// Generates a numbered plain-text checklist ordered by item placement sequence.
    private func generateSetupChecklist() -> String {
        var lines = [
            "AGSU SETUP CHECKLIST",
            "Generated from Army Uniform Builder: AGSU",
            "Reference: DA PAM 670-1, 26 January 2021",
            "",
            "Soldier: \(vm.soldier.grade) · \(vm.soldier.branch.capitalized) · \(vm.soldier.component.rawValue)",
            "",
        ]

        // Emit items in the order they should be physically attached to the coat
        let setupOrder: [ItemCategory] = [
            .rank, .branchInsignia, .usInsignia, .ribbon,
            .badge(group: 1), .badge(group: 2), .badge(group: 3),
            .badge(group: 4), .badge(group: 5), .idBadge, .tab
        ]
        var step = 1
        for category in setupOrder {
            for item in vm.placedItems where item.item.category == category {
                let name        = item.item.id.replacingOccurrences(of: "_", with: " ").capitalized
                let measurement = item.measurements.first.map { $0.value } ?? "per regulation"
                lines.append("\(step). Attach \(name) — \(measurement) (\(item.regulationRef))")
                step += 1
            }
        }

        lines.append("")
        lines.append("Not affiliated with or endorsed by the U.S. Army or Department of Defense.")
        return lines.joined(separator: "\n")
    }
}

// MARK: - ShareSheet

/// Thin `UIViewControllerRepresentable` wrapper around `UIActivityViewController`.
/// Presents the iOS share sheet with the given items array.
struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
