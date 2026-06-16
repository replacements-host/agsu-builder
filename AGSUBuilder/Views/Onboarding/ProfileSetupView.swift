import SwiftUI

struct ProfileSetupView: View {
    @StateObject private var vm = ProfileViewModel()
    @State private var branchSearch = ""
    @State private var gradeSearch = ""
    @State private var navigateToBuilder = false

    private let steps = ["PROFILE", "INSIGNIA", "REVIEW", "ADJUST"]

    var filteredBranches: [BranchRecord] {
        let all = DataLoader.shared.branchInsignia
        if branchSearch.isEmpty { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(branchSearch) }
    }

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

                // RANK CATEGORY
                sectionHeader("RANK CATEGORY")
                Picker("Rank Category", selection: $vm.rankCategory) {
                    ForEach(Soldier.RankCategory.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: vm.rankCategory) { _ in vm.updateGradeForCategory() }

                // GENDER
                sectionHeader("GENDER")
                Picker("Gender", selection: $vm.gender) {
                    ForEach(Soldier.Gender.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                // GRADE
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

                // BRANCH
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

                // COMPONENT
                sectionHeader("COMPONENT")
                Picker("Component", selection: $vm.component) {
                    ForEach(Soldier.Component.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                // COMBAT VETERAN
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

                // Continue button
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
