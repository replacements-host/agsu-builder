import SwiftUI

/// Half-sheet that shows the regulation citation, measurements, and options for a tapped item.
///
/// Presented as a `.medium` detent sheet from `CanvasView` when the user taps
/// a `PlacedItem`. The sheet includes:
/// - The DA PAM 670-1 paragraph reference
/// - Item thumbnail (from asset catalog, or gray placeholder)
/// - Bullet-point measurement specs
/// - Out-of-policy warning when `item.isOutOfPolicy == true`
/// - "Adjust This Item →" button that closes the sheet and opens `AdjustModeView`
/// - "Report placement error" link that opens a `mailto:` draft via `ErrorReportView`
struct RegulationSheetView: View {

    let item: PlacedItem
    @Binding var isPresented: Bool
    /// Callback invoked when the user taps "Adjust This Item →".
    let onAdjust: () -> Void

    @State private var showErrorReport = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {

                    // Regulation citation header
                    HStack {
                        Text("REGULATION")
                            .font(AppFont.sectionHeader)
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                        Text(item.regulationRef)
                            .font(AppFont.semiBold(13))
                            .foregroundColor(.brandGold)
                    }

                    Divider()

                    // Item name derived from the id string
                    Text(item.item.id.replacingOccurrences(of: "_", with: " ").uppercased())
                        .font(AppFont.bold(24))
                        .foregroundColor(Color(.label))

                    // Thumbnail + measurement bullets
                    HStack(alignment: .top, spacing: Spacing.md) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(item.item.id)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(8)
                            )
                            .frame(width: 80, height: 60)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Placement per DA PAM 670-1")
                                .font(AppFont.bodyPrimary)
                                .foregroundColor(Color(.label))

                            ForEach(Array(item.measurements.enumerated()), id: \.offset) { _, m in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.brandGold)
                                        .frame(width: 5, height: 5)
                                    Text("\(m.label): \(m.value)")
                                        .font(AppFont.bodySecondary)
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                            }

                            if item.measurements.isEmpty {
                                Text("See regulation for exact placement specifications.")
                                    .font(AppFont.bodySecondary)
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                        }
                    }

                    // Out-of-policy warning banner
                    if item.isOutOfPolicy {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.brandAmber)
                            Text(item.soldier.gender == .female
                                ? "Outside body-shape adjustment range (>1/4\")"
                                : "Outside prescribed position — DA PAM 670-1")
                                .font(AppFont.bodySecondary)
                                .foregroundColor(.brandAmber)
                        }
                        .padding(Spacing.sm)
                        .background(Color.brandAmber.opacity(0.1))
                        .cornerRadius(Radius.sm)
                    }

                    Divider()

                    // Action row
                    HStack {
                        Button("Close") { isPresented = false }
                            .font(AppFont.buttonLabel)
                            .foregroundColor(Color(.secondaryLabel))

                        Spacer()

                        Button("Adjust This Item →") {
                            isPresented = false
                            onAdjust()
                        }
                        .font(AppFont.buttonLabel)
                        .foregroundColor(.brandGold)
                    }

                    // Error report link — opens ErrorReportView as a nested sheet
                    Button("Report placement error") { showErrorReport = true }
                        .font(AppFont.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.sm)
                }
                .padding(Spacing.lg)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showErrorReport) {
            ErrorReportView(item: item, isPresented: $showErrorReport)
        }
    }
}

// MARK: - ErrorReportView

/// A form that pre-fills item details and opens a `mailto:` draft when submitted.
///
/// Collected fields: item id, regulation ref, grade, branch, and a free-text
/// description of the placement error. Useful for crowd-sourced regulation
/// correctness before automating a TIOH fetch pipeline.
struct ErrorReportView: View {

    let item: PlacedItem
    @Binding var isPresented: Bool
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("PRE-FILLED INFORMATION") {
                    LabeledContent("Item",       value: item.item.id.replacingOccurrences(of: "_", with: " ").capitalized)
                    LabeledContent("Regulation", value: item.regulationRef)
                    LabeledContent("Grade",      value: item.soldier.grade)
                    LabeledContent("Branch",     value: item.soldier.branch.capitalized)
                }
                Section("WHAT'S WRONG?") {
                    TextEditor(text: $errorText)
                        .font(AppFont.bodyPrimary)
                        .frame(height: 100)
                }
                Section {
                    Button("Submit Report") {
                        submitError()
                        isPresented = false
                    }
                    .font(AppFont.buttonLabel)
                    .foregroundColor(.brandGold)
                    .disabled(errorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Report Error")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    /// Opens a `mailto:` URL pre-filled with item metadata and the user's error description.
    private func submitError() {
        let subject = "Placement Error: \(item.item.id) — \(item.regulationRef)"
        let body = """
            Item: \(item.item.id)
            Regulation: \(item.regulationRef)
            Grade: \(item.soldier.grade)
            Branch: \(item.soldier.branch)

            Issue:
            \(errorText)
            """
        let encoded = "mailto:support@agsubuilder.app?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: encoded) {
            UIApplication.shared.open(url)
        }
    }
}
