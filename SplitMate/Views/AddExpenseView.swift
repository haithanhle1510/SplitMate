import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID

    @State private var title = ""
    @State private var amountText = ""
    @State private var paidById: UUID? = nil
    @State private var selectedParticipants: Set<UUID> = []
    @State private var category: ExpenseCategory = .food
    @State private var date = Date()
    @State private var note = ""

    private var group: SplitGroup? { viewModel.groups.first { $0.id == groupId } }

    private var parsedAmount: Double { Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private var perPersonShare: Double {
        selectedParticipants.isEmpty || parsedAmount == 0 ? 0 : parsedAmount / Double(selectedParticipants.count)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && parsedAmount > 0
            && paidById != nil
            && !selectedParticipants.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                if group?.members.isEmpty != false {
                    noMembersPlaceholder
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            titleSection
                            amountSection
                            if let group {
                                paidBySection(group: group)
                                participantsSection(group: group)
                            }
                            categorySection
                            dateSection
                            noteSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                        splitSummaryBar
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.nunito(15, weight: .semibold))
                        .foregroundColor(.appTerra)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveAndDismiss() }
                        .font(.nunito(15, weight: .heavy))
                        .foregroundColor(isValid ? .appTerra : .appWarmGray)
                        .disabled(!isValid)
                }
            }
        }
    }

    //No members guard

    private var noMembersPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color.appPeach).frame(width: 80, height: 80)
                Text("👥").font(.system(size: 34))
            }
            Text("Add members first")
                .font(.nunito(18, weight: .heavy))
                .foregroundColor(.appText)
            Text("Go to Settings to add people\nbefore logging an expense.")
                .font(.nunito(14, weight: .semibold))
                .foregroundColor(.appMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    //Sections

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("TITLE")
            TextField("e.g. Groceries", text: $title)
                .font(.nunito(16, weight: .semibold))
                .foregroundColor(.appText)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color.appWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(title.isEmpty ? Color.appBorder : Color.appTerra, lineWidth: 1.5)
                )
                .cornerRadius(12)
        }
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("AMOUNT")
            HStack(alignment: .center, spacing: 4) {
                Text("$")
                    .font(.nunito(34, weight: .heavy))
                    .foregroundColor(.appText)
                TextField("0.00", text: $amountText)
                    .font(.nunito(40, weight: .heavy))
                    .foregroundColor(.appText)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appWhite)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appBorder, lineWidth: 1.5)
            )
            .cornerRadius(12)
        }
    }

    private func paidBySection(group: SplitGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("PAID BY")
            HStack(spacing: 14) {
                ForEach(group.members) { member in
                    paidByAvatar(member: member)
                }
                Spacer()
            }
        }
    }

    private func paidByAvatar(member: Member) -> some View {
        let isSelected = paidById == member.id
        return Button {
            paidById = member.id
            if !selectedParticipants.contains(member.id) {
                selectedParticipants.insert(member.id)
            }
            Haptics.selection()
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    AvatarView(name: member.name, size: 44)
                    if isSelected {
                        Circle()
                            .stroke(Color.appTerra, lineWidth: 2.5)
                            .frame(width: 44, height: 44)
                    }
                }
                Text(member.name.components(separatedBy: " ").first ?? member.name)
                    .font(.nunito(11, weight: .bold))
                    .foregroundColor(isSelected ? .appTerra : .appMuted)
            }
        }
        .buttonStyle(.plain)
    }

    private func participantsSection(group: SplitGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("PARTICIPANTS")
            HStack(spacing: 14) {
                ForEach(group.members) { member in
                    participantAvatar(member: member)
                }
                Spacer()
            }
        }
    }

    private func participantAvatar(member: Member) -> some View {
        let isSelected = selectedParticipants.contains(member.id)
        return Button {
            if isSelected {
                if member.id != paidById {
                    selectedParticipants.remove(member.id)
                }
            } else {
                selectedParticipants.insert(member.id)
            }
            Haptics.selection()
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    AvatarView(name: member.name, size: 44)
                        .opacity(isSelected ? 1 : 0.35)
                    if isSelected {
                        Circle()
                            .stroke(Color.appTerra, lineWidth: 2.5)
                            .frame(width: 44, height: 44)
                    }
                }
                Text(member.name.components(separatedBy: " ").first ?? member.name)
                    .font(.nunito(11, weight: .bold))
                    .foregroundColor(isSelected ? .appTerra : .appWarmGray)
            }
        }
        .buttonStyle(.plain)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("CATEGORY")
            let rows = [
                Array(ExpenseCategory.allCases.prefix(3)),
                Array(ExpenseCategory.allCases.dropFirst(3))
            ]
            VStack(alignment: .leading, spacing: 10) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { cat in
                            categoryChip(cat)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private func categoryChip(_ cat: ExpenseCategory) -> some View {
        let isSelected = category == cat
        return Button {
            category = cat
            Haptics.selection()
        } label: {
            Text(cat.displayName)
                .font(.nunito(14, weight: .bold))
                .foregroundColor(isSelected ? .appWhite : .appText)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.appTerra : Color.appWhite)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.appBorder, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("DATE")
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .font(.nunito(15, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.appWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appBorder, lineWidth: 1.5)
                )
                .cornerRadius(12)
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("NOTE (OPTIONAL)")
            TextField("Add a note...", text: $note, axis: .vertical)
                .font(.nunito(15, weight: .semibold))
                .foregroundColor(.appText)
                .lineLimit(3, reservesSpace: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.appWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appBorder, lineWidth: 1.5)
                )
                .cornerRadius(12)
        }
    }

    private var splitSummaryBar: some View {
        let count = selectedParticipants.count
        let shareText = count > 0 && parsedAmount > 0
            ? String(format: "$%.2f each · across %d %@", perPersonShare, count, count == 1 ? "person" : "people")
            : "Select participants"

        return VStack(alignment: .leading, spacing: 2) {
            Text("Split equally")
                .font(.nunito(13, weight: .heavy))
                .foregroundColor(.appText)
            Text(shareText)
                .font(.nunito(12, weight: .semibold))
                .foregroundColor(.appText.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.appWhite)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder, lineWidth: 1.5)
        )
        .cornerRadius(12)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(11, weight: .heavy))
            .foregroundColor(.appMuted)
            .tracking(0.8)
    }

    private func saveAndDismiss() {
        guard isValid, let paidById else { return }
        viewModel.addExpense(
            toGroupId: groupId,
            title: title.trimmingCharacters(in: .whitespaces),
            amount: parsedAmount,
            paidBy: paidById,
            participantIds: Array(selectedParticipants),
            category: category,
            date: date,
            note: note.isEmpty ? nil : note
        )
        Haptics.success()
        dismiss()
    }
}
