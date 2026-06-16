import SwiftUI
import Photos

/// Offers export formats plus uniform saving.
///
/// **Export options:**
/// 1. **PDF Spec Sheet** — `UIGraphicsPDFRenderer` generates an 8.5×11" page with the
///    coat image and a regulation citation table. Shared as a `.pdf` file URL.
/// 2. **Image (Front View)** — `ImageRenderer` captures the coat + insignia at 3× scale.
/// 3. **Save to Photos** — Writes the coat image to the Camera Roll.
/// 4. **Setup Checklist** — Plain text ordered list of attachment steps with measurements.
/// 5. **Share to Unit** — Passes a `UIImage` to the iOS share sheet.
///
/// Saving a uniform delegates to the shared `SavedUniformsViewModel` environment object.
struct ExportView: View {

    @ObservedObject var vm: CanvasViewModel
    @EnvironmentObject private var savedVM: SavedUniformsViewModel
    @EnvironmentObject private var navCoordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet       = false
    @State private var showSaveDialog       = false
    @State private var showPhotoSavedAlert  = false
    @State private var uniformName          = ""
    @State private var shareItems: [Any]    = []

    var body: some View {
        List {

            // ── Coat preview ───────────────────────────────────────────────────
            Section {
                GeometryReader { geo in
                    ZStack {
                        CoatLayerView(geometry: vm.soldier.coatVariant.geometry)
                        InsigniaLayerView(
                            placedItems:    vm.placedItems,
                            selectedItemID: nil,
                            canvasSize:     geo.size
                        )
                    }
                }
                .frame(height: 300)
                .cornerRadius(Radius.md)
                .listRowInsets(EdgeInsets())
            } header: {
                Text("\(vm.soldier.grade.uppercased()) · \(vm.soldier.branch.capitalized) · \(vm.soldier.component.rawValue.uppercased())")
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
                          subtitle: "Share coat image via iOS share sheet") {
                    exportImage()
                }
                exportRow(icon: "photo.on.rectangle.angled",
                          title: "Save to Photos",
                          subtitle: "Save coat image to your Camera Roll") {
                    saveToPhotos()
                }
                exportRow(icon: "list.number",
                          title: "Setup Checklist",
                          subtitle: "Step-by-step instructions with measurements") {
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
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: exportPDF) {
                    Text("PDF")
                        .font(AppFont.buttonLabel)
                        .foregroundColor(.brandGold)
                }
                Button(action: {
                    navCoordinator.shouldReturnToHome = true
                    dismiss()
                }) {
                    Image(systemName: "house")
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
                savedVM.save(canvasVM: vm, name: name)
                uniformName = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Give this uniform a name to find it later.")
        }
        .alert("Saved to Photos", isPresented: $showPhotoSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your uniform image has been saved to your Camera Roll.")
        }
    }

    // MARK: - Row Builder

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
        let pdf = generatePDF(coatImage: renderCanvasImage())
        let fileName = "agsu_\(vm.soldier.grade)_spec_sheet.pdf"
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pdf.write(to: url)
        shareItems = [url]
        showShareSheet = true
    }

    private func exportImage() {
        shareItems = [renderCanvasImage()]
        showShareSheet = true
    }

    private func saveToPhotos() {
        let image = renderCanvasImage()
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, _ in
                DispatchQueue.main.async {
                    if success { showPhotoSavedAlert = true }
                }
            })
        }
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

    /// Renders the coat and all placed insignia into a `UIImage` at 3× scale.
    private func renderCanvasImage() -> UIImage {
        let renderer = ImageRenderer(content:
            ZStack {
                CoatLayerView(geometry: vm.soldier.coatVariant.geometry)
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

            "ARMY UNIFORM BUILDER: AGSU — Specification Sheet".draw(
                at: CGPoint(x: 36, y: 36),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.black]
            )
            "\(vm.soldier.grade) · \(vm.soldier.branch.capitalized) · \(vm.soldier.component.rawValue)".draw(
                at: CGPoint(x: 36, y: 60),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.darkGray]
            )

            coatImage.draw(in: CGRect(x: 36, y: 90, width: 200, height: 300))

            var tableX: CGFloat = 260
            var tableY: CGFloat = 90
            let smallFont = UIFont.systemFont(ofSize: 9)
            let boldFont  = UIFont.boldSystemFont(ofSize: 9)

            "ITEM".draw(at:       CGPoint(x: tableX,       y: tableY), withAttributes: [.font: boldFont])
            "REGULATION REF".draw(at: CGPoint(x: tableX + 160, y: tableY), withAttributes: [.font: boldFont])
            tableY += 14
            cgCtx.setStrokeColor(UIColor.lightGray.cgColor)
            cgCtx.stroke(CGRect(x: tableX, y: tableY, width: 316, height: 0.5))
            tableY += 4

            for item in vm.placedItems where tableY < 750 {
                let name = item.item.id.replacingOccurrences(of: "_", with: " ").capitalized
                name.draw(at: CGPoint(x: tableX, y: tableY), withAttributes: [.font: smallFont])
                item.regulationRef.draw(at: CGPoint(x: tableX + 160, y: tableY),
                                        withAttributes: [.font: smallFont, .foregroundColor: UIColor.systemOrange])
                tableY += 12
                if let m = item.measurements.first {
                    "\(m.label): \(m.value)".draw(at: CGPoint(x: tableX + 8, y: tableY),
                                                   withAttributes: [.font: smallFont, .foregroundColor: UIColor.gray])
                    tableY += 10
                }
            }

            "Not affiliated with or endorsed by the U.S. Army. DA PAM 670-1, 26 January 2021.".draw(
                at: CGPoint(x: 36, y: 760),
                withAttributes: [.font: UIFont.systemFont(ofSize: 7), .foregroundColor: UIColor.lightGray]
            )
        }
    }

    /// Generates a numbered plain-text checklist with specific measurement guidance.
    private func generateSetupChecklist() -> String {
        var lines = [
            "AGSU SETUP CHECKLIST",
            "Generated from Army Uniform Builder: AGSU",
            "Reference: DA PAM 670-1, 26 January 2021",
            "",
            "Soldier: \(vm.soldier.grade) · \(vm.soldier.branch.capitalized) · \(vm.soldier.component.rawValue)",
            "Gender: \(vm.soldier.gender.rawValue)",
            "",
            "PREPARATION",
            "  • Press coat, ensuring all creases align with regulation",
            "  • Lay coat flat on a clean surface, front facing up",
            "  • Have a ruler (in inches) ready for measurements below",
            "",
            "ATTACHMENT SEQUENCE",
        ]

        let setupOrder: [ItemCategory] = [
            .rank, .branchInsignia, .usInsignia, .ribbon,
            .badge(group: 1), .badge(group: 2), .badge(group: 3),
            .badge(group: 4), .badge(group: 5), .idBadge, .tab
        ]
        var step = 1
        for category in setupOrder {
            for item in vm.placedItems where item.item.category == category {
                let name = item.item.id.replacingOccurrences(of: "_", with: " ").capitalized
                let detail: String
                if let m = item.measurements.first {
                    detail = "\(m.label): \(m.value)"
                } else {
                    switch item.item.category {
                    case .rank:
                        detail = vm.soldier.rankCategory == .enlisted
                            ? "Center on collar, point 5/8\" from each collar tip"
                            : "Center on shoulder loop"
                    case .branchInsignia:
                        detail = "Left collar, centered 1\" from bottom edge, 1-1/4\" from tip"
                    case .usInsignia:
                        detail = "Right collar, centered 1\" from bottom edge, 1-1/4\" from tip"
                    case .ribbon:
                        detail = "Ribbon rack, 1/8\" above left breast pocket top, centered on pocket"
                    case .badge(let g):
                        detail = "Badge Group \(g): above ribbon rack in group-precedence order"
                    case .idBadge:
                        detail = "Centered on breast pocket, 1/4\" below pocket seam"
                    case .tab:
                        detail = "Left sleeve, stacked per para 22-16d precedence table"
                    default:
                        detail = "See \(item.regulationRef)"
                    }
                }
                lines.append("\(step). \(name)")
                lines.append("   \(detail)")
                lines.append("   Ref: \(item.regulationRef)")
                lines.append("")
                step += 1
            }
        }

        lines.append("FINAL CHECK")
        lines.append("  • Verify all pin-on items are secured with clutch backs")
        lines.append("  • Confirm ribbon rack is level")
        lines.append("  • Cross-reference with current DA PAM 670-1 for any recent changes")
        lines.append("")
        lines.append("Not affiliated with or endorsed by the U.S. Army or Department of Defense.")
        return lines.joined(separator: "\n")
    }
}

// MARK: - ShareSheet

/// Thin `UIViewControllerRepresentable` wrapper around `UIActivityViewController`.
struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
