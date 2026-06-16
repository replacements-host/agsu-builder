import SwiftUI

/// Step 1 of the four-step setup flow: collects the Soldier's profile data.
///
/// Sections (top to bottom):
/// 1. **Progress dots** — four labeled steps (PROFILE → INSIGNIA → REVIEW → ADJUST).
/// 2. **Rank Category** — segmented: Enlisted / Officer / Warrant Officer.
/// 3. **Gender** — segmented: Male / Female (affects coat variant and policy threshold).
/// 4. **Grade** — searchable horizontal chip list filtered to valid grades for the
///    selected category; resets when category changes.
/// 5. **Branch** — searchable 2-column grid of all branches from `branch_insignia.json`.
/// 6. **Component** — segmented: Active / Reserve / Guard.
/// 7. **Combat Veteran** — toggle affecting CSIB eligibility.
/// 8. **BUILD MY UNIFORM** → `BuilderFlowView(soldier:)`
struct ProfileSetupView: View {

    @StateObject private var vm  = ProfileViewModel()
    @State private var branchSearch = ""
    @State private var gradeSearch  = ""

    private let steps = ["PROFILE", "INSIGNIA", "REVIEW", "ADJUST"]

    /// Branches filtered by the search field, or all branches if the field is empty.
    var filteredBranches: [BranchRecord] {
        let all = DataLoader.shared.branchInsignia
        if branchSearch.isEmpty { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(branchSearch) }
    }

    /// Grades for the current rank category, filtered by the grade search field.
    var filteredGrades: [String] {
        if gradeSearch.isEmpty { return vm.availableGrades }
        return vm.availableGrades.filter { $0.localizedCaseInsensitiveContains(gradeSearch) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {

                // Progress dots
                HStack(spacing: Spacing.sm) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(i == 0 ? Color.brandGold : Color(.separator))
                                .frame(width: 8, height: 8)
                            Text(step)
                                .font(AppFont.caption)
                                .foregroundColor(i == 0 ? .brandGold : Color(.tertiaryLabel))
                        }
                        if i < steps.count - 1 {
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 12)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)

                // Rank category
                sectionHeader("RANK CATEGORY")
                Picker("Rank Category", selection: $vm.rankCategory) {
                    ForEach(Soldier.RankCategory.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: vm.rankCategory) { _ in
                    // Reset grade to the first valid option for the new category
                    vm.updateGradeForCategory()
                }

                // Gender
                sectionHeader("GENDER")
                Picker("Gender", selection: $vm.gender) {
                    ForEach(Soldier.Gender.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                // Grade
                sectionHeader("GRADE")
                TextField("Search grades...", text: $gradeSearch)
                    .textFieldStyle(.roundedBorder)
                    .font(AppFont.bodyPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(filteredGrades, id: \.self) { grade in
                            Button(action: { vm.grade = grade }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(grade)
                                        .font(AppFont.semiBold(14))
                                    Text(vm.gradeTitle[grade] ?? "")
                                        .font(AppFont.caption)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(Spacing.sm)
                                .frame(width: 120, alignment: .leading)
                                .background(vm.grade == grade ? Color.brandGold.opacity(0.2) : Color(.secondarySystemBackground))
                                .cornerRadius(Radius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.sm)
                                        .stroke(vm.grade == grade ? Color.brandGold : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .foregroundColor(Color(.label))
                        }
                    }
                }

                // Branch
                sectionHeader("BRANCH")
                TextField("Search branches...", text: $branchSearch)
                    .textFieldStyle(.roundedBorder)
                    .font(AppFont.bodyPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                    ForEach(filteredBranches) { branch in
                        Button(action: { vm.branch = branch.id }) {
                            Text(branch.name)
                                .font(AppFont.regular(14))
                                .padding(Spacing.sm)
                                .frame(maxWidth: .infinity)
                                .background(vm.branch == branch.id ? Color.brandGold.opacity(0.2) : Color(.secondarySystemBackground))
                                .cornerRadius(Radius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.sm)
                                        .stroke(vm.branch == branch.id ? Color.brandGold : Color.clear, lineWidth: 1.5)
                                )
                        }
                        .foregroundColor(Color(.label))
                    }
                }

                // Component
                sectionHeader("COMPONENT")
                Picker("Component", selection: $vm.component) {
                    ForEach(Soldier.Component.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                // Combat veteran toggle — affects CSIB and combat patch eligibility
                Toggle(isOn: $vm.isCombatVeteran) {
                    VStack(alignment: .leading) {
                        Text("COMBAT VETERAN")
                            .font(AppFont.sectionHeader)
                            .foregroundColor(Color(.secondaryLabel))
                        Text("Affects combat patch eligibility")
                            .font(AppFont.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                .tint(.brandGold)

                // Continue to insignia selection
                NavigationLink(destination: BuilderFlowView(soldier: vm.soldier)) {
                    Text("BUILD MY UNIFORM")
                        .font(AppFont.buttonLabel)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.brandGold)
                        .cornerRadius(Radius.lg)
                }
                .padding(.top, Spacing.md)
            }
            .padding(Spacing.md)
        }
        .navigationTitle("Your Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Section header label with 1.2 pt letter-spacing.
    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppFont.sectionHeader)
            .foregroundColor(Color(.secondaryLabel))
            .kerning(1.2)
    }
}

#Preview {
    NavigationStack { ProfileSetupView() }
}
