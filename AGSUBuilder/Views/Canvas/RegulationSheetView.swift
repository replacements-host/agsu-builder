import SwiftUI

struct RegulationSheetView: View {
    let item: PlacedItem
    @Binding var isPresented: Bool
    let onAdjust: () -> Void

    @State private var showErrorReport = false
    @State private var errorText = ""

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

                    // Item name
                    Text(item.item.id.replacingOccurrences(of: "_", with: " ").uppercased())
                        .font(AppFont.bold(24))
                        .foregroundColor(Color(.label))

                    // Image + description
                    HStack(alignment: .top, spacing: Spacing.md) {
                        // Image placeholder
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

                    // Action buttons
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

                    // Error report link
                    Button("Report placement error") {
                        showErrorReport = true
                    }
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

struct ErrorReportView: View {
    let item: PlacedItem
    @Binding var isPresented: Bool
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("PRE-FILLED INFORMATION") {
                    LabeledContent("Item", value: item.item.id.replacingOccurrences(of: "_", with: " ").capitalized)
                    LabeledContent("Regulation", value: item.regulationRef)
                    LabeledContent("Grade", value: item.soldier.grade)
                    LabeledContent("Branch", value: item.soldier.branch.capitalized)
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

    private func submitError() {
        // Open mailto: link for error reporting
        let subject = "Placement Error: \(item.item.id) — \(item.regulationRef)"
        let body = "Item: \(item.item.id)\nRegulation: \(item.regulationRef)\nGrade: \(item.soldier.grade)\nBranch: \(item.soldier.branch)\n\nIssue:\n\(errorText)"
        let encoded = "mailto:support@agsubuilder.app?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: encoded) {
            UIApplication.shared.open(url)
        }
    }
}
