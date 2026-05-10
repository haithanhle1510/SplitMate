import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    /// When set, the form edits that expense (`Save` calls `updateExpense`).
    var expenseId: UUID? = nil

    @State private var title = ""
    @State private var amountText = ""
    @State private var paidById: UUID? = nil
    @State private var selectedParticipants: Set<UUID> = []
    @State private var splitType: ExpenseSplitType = .equal
    @State private var memberAmounts: [UUID: String] = [:]
    @State private var memberPercentages: [UUID: String] = [:]
    @State private var category: ExpenseCategory = .food
    @State private var date = Date()
    @State private var note = ""
    @State private var showNoteField = false
    /// Lets initial edit hydration finish before `splitType` / participant `onChange` overwrites fields.
    @State private var hasCompletedInitialLoad = false

    @FocusState private var focus: AddExpenseFocus?

    private enum AddExpenseFocus: Hashable {
        case title, amount, note
    }

    private static let percentageSumEpsilon = 0.5
    private static let exactSumEpsilon = 0.02

    private var group: SplitGroup? { viewModel.groups.first { $0.id == groupId } }
    private var isEditMode: Bool { expenseId != nil }
    private var parsedAmount: Double { Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private var orderedSelectedMembers: [Member] {
        guard let group else { return [] }
        return group.members.filter { selectedParticipants.contains($0.id) }
    }

    private var totalAssignedAmount: Double {
        selectedParticipants.reduce(0) { $0 + (Double(memberAmounts[$1] ?? "") ?? 0) }
    }

    private var totalAssignedPercentage: Double {
        selectedParticipants.reduce(0) { $0 + (Double(memberPercentages[$1] ?? "") ?? 0) }
    }

    private var percentagePayload: [(memberId: UUID, percentage: Double)]? {
        let members = orderedSelectedMembers
        guard members.count == selectedParticipants.count else { return nil }
        var parts: [(UUID, Double)] = []
        for m in members {
            guard let raw = memberPercentages[m.id]?.trimmingCharacters(in: .whitespaces),
                  let v = Double(raw.replacingOccurrences(of: ",", with: ".")) else { return nil }
            parts.append((m.id, v))
        }
        let sum = parts.reduce(0) { $0 + $1.1 }
        guard abs(sum - 100) < Self.percentageSumEpsilon else { return nil }
        return parts
    }

    private var exactPayload: [(memberId: UUID, amount: Double)]? {
        let members = orderedSelectedMembers
        guard members.count == selectedParticipants.count else { return nil }
        var parts: [(UUID, Double)] = []
        for m in members {
            guard let raw = memberAmounts[m.id]?.trimmingCharacters(in: .whitespaces),
                  let v = Double(raw.replacingOccurrences(of: ",", with: ".")) else { return nil }
            parts.append((m.id, v))
        }
        let sum = parts.reduce(0) { $0 + $1.1 }
        guard abs(sum - parsedAmount) < Self.exactSumEpsilon else { return nil }
        return parts
    }

    private var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              parsedAmount > 0,
              paidById != nil,
              !selectedParticipants.isEmpty else { return false }
        switch splitType {
        case .equal:       return true
        case .percentage:  return percentagePayload != nil
        case .exactAmount: return exactPayload != nil
        }
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
                            categorySection
                            amountSection
                            if let group {
                                paidBySection(group: group)
                                participantsSection(group: group)
                            }
                            splitMethodSection
                            if let group, !selectedParticipants.isEmpty {
                                splitDetailSection(group: group)
                            }
                            dateSection
                            noteSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationTitle(isEditMode ? "Edit Expense" : "New Expense")
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
            .onAppear {
                if let id = expenseId {
                    hydrateForEdit(expenseId: id)
                    DispatchQueue.main.async { hasCompletedInitialLoad = true }
                } else {
                    applyCreateModeDefaults()
                    hasCompletedInitialLoad = true
                }
            }
            .onChange(of: splitType) { _, newValue in
                guard hasCompletedInitialLoad else { return }
                syncSplitFields(for: newValue)
                Haptics.selection()
            }
            .onChange(of: selectedParticipants) { _, _ in
                guard hasCompletedInitialLoad else { return }
                syncSplitFields(for: splitType)
            }
        }
    }

    // MARK: - Setup

    private func applyCreateModeDefaults() {
        guard let g = viewModel.groups.first(where: { $0.id == groupId }) else { return }
        if selectedParticipants.isEmpty {
            selectedParticipants = Set(g.members.map(\.id))
        }
        if !note.isEmpty { showNoteField = true }
        syncSplitFields(for: splitType)
    }

    private func hydrateForEdit(expenseId: UUID) {
        guard let group = viewModel.groups.first(where: { $0.id == groupId }),
              let expense = group.expenses.first(where: { $0.id == expenseId }) else {
            dismiss()
            return
        }
        title = expense.title
        amountText = String(format: "%.2f", expense.totalAmount)
        paidById = expense.paidByMemberId
        selectedParticipants = Set(expense.participants.map(\.memberId))
        splitType = expense.splitType
        category = expense.category
        date = expense.date
        if let n = expense.note, !n.isEmpty {
            note = n
            showNoteField = true
        } else {
            note = ""
            showNoteField = false
        }
        memberPercentages = [:]
        memberAmounts = [:]
        switch expense.splitType {
        case .equal:
            break
        case .percentage:
            for p in expense.participants {
                guard let pct = p.percentage else { continue }
                memberPercentages[p.memberId] = abs(pct - pct.rounded()) < 0.001
                    ? String(format: "%.0f", pct)
                    : String(format: "%g", pct)
            }
        case .exactAmount:
            for p in expense.participants {
                memberAmounts[p.memberId] = String(format: "%.2f", p.owedAmount)
            }
        }
    }

    // MARK: - No members guard

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
            Text("Open Settings and add people\nto this group before logging an expense.")
                .font(.nunito(14, weight: .semibold))
                .foregroundColor(.appMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sections

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Title")
            TextField("Groceries, dinner, rent…", text: $title)
                .font(.nunito(16, weight: .semibold))
                .foregroundColor(.appText)
                .focused($focus, equals: .title)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color.appWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appBorder, lineWidth: 1.5)
                )
                .cornerRadius(12)
        }
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Amount")
            HStack(alignment: .center, spacing: 4) {
                Text("$")
                    .font(.nunito(34, weight: .heavy))
                    .foregroundColor(.appText)
                TextField("0.00", text: $amountText)
                    .font(.nunito(40, weight: .heavy))
                    .foregroundColor(.appText)
                    .keyboardType(.decimalPad)
                    .focused($focus, equals: .amount)
                    .frame(maxWidth: .infinity)
                    .onChange(of: amountText) { _, _ in
                        if splitType == .equal { resetSplitInputs() }
                    }
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
            sectionLabel("Paid by")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(group.members) { member in
                        paidByAvatar(member: member)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func paidByAvatar(member: Member) -> some View {
        let isSelected = paidById == member.id
        return Button {
            paidById = member.id
            if !selectedParticipants.contains(member.id) {
                selectedParticipants.insert(member.id)
                resetSplitInputs()
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
        .accessibilityLabel("Paid by \(member.name)\(isSelected ? ", selected" : "")")
    }

    private func participantsSection(group: SplitGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Split between")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(group.members) { member in
                        participantAvatar(member: member)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func participantAvatar(member: Member) -> some View {
        let isSelected = selectedParticipants.contains(member.id)
        return Button {
            if isSelected {
                if member.id != paidById {
                    selectedParticipants.remove(member.id)
                    memberAmounts.removeValue(forKey: member.id)
                    memberPercentages.removeValue(forKey: member.id)
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
        .accessibilityLabel("Split with \(member.name), \(isSelected ? "selected" : "not selected")")
    }

    // MARK: - Split Method Picker

    private var splitMethodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("SPLIT METHOD")
            HStack(spacing: 0) {
                ForEach(ExpenseSplitType.allCases, id: \.self) { method in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            splitType = method
                        }
                        Haptics.selection()
                    } label: {
                        Text(method.shortLabel)
                            .font(.nunito(14, weight: .bold))
                            .foregroundColor(splitType == method ? .appWhite : .appText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(splitType == method ? Color.appTerra : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.appWhite)
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(Color.appBorder, lineWidth: 1.5)
            )
            .cornerRadius(13)
        }
    }

    // MARK: - Split Detail Sections

    @ViewBuilder
    private func splitDetailSection(group: SplitGroup) -> some View {
        switch splitType {
        case .equal:
            splitEquallyPreview
        case .exactAmount:
            splitByAmountSection(group: group)
        case .percentage:
            splitByPercentageSection(group: group)
        }
    }

    private var splitEquallyPreview: some View {
        let count = selectedParticipants.count
        let shareText = count > 0 && parsedAmount > 0
            ? String(format: "$%.2f each · %d %@", parsedAmount / Double(count), count, count == 1 ? "person" : "people")
            : "Select participants to preview split"

        return HStack(spacing: 10) {
            Image(systemName: "equal.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.appTerra)
            VStack(alignment: .leading, spacing: 2) {
                Text("Split equally")
                    .font(.nunito(13, weight: .heavy))
                    .foregroundColor(.appText)
                Text(shareText)
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(.appMuted)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.appWhite)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder, lineWidth: 1.5)
        )
        .cornerRadius(12)
    }

    private func splitByAmountSection(group: SplitGroup) -> some View {
        let participants = group.members.filter { selectedParticipants.contains($0.id) }
        let remaining = parsedAmount - totalAssignedAmount
        let isBalanced = abs(remaining) < 0.01

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("SPLIT AMOUNTS")
                Spacer()
                if parsedAmount > 0 {
                    Text(isBalanced ? "✓ Balanced" : (remaining < 0
                        ? String(format: "$%.2f over", abs(remaining))
                        : String(format: "$%.2f left", remaining)))
                        .font(.nunito(12, weight: .bold))
                        .foregroundColor(isBalanced ? .appTerra : (remaining < 0 ? .red : .appMuted))
                }
            }
            VStack(spacing: 8) {
                ForEach(participants) { member in
                    MemberAmountRow(
                        member: member,
                        text: Binding(
                            get: { memberAmounts[member.id] ?? "" },
                            set: { memberAmounts[member.id] = $0 }
                        )
                    )
                }
            }
            if participants.count > 1 && parsedAmount > 0 {
                splitActionRow(
                    fillAction: { fillEqually() },
                    clearAction: { memberAmounts = [:] }
                )
            }
        }
    }

    private func splitByPercentageSection(group: SplitGroup) -> some View {
        let participants = group.members.filter { selectedParticipants.contains($0.id) }
        let remaining = 100.0 - totalAssignedPercentage
        let isBalanced = abs(remaining) < 0.01

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("SPLIT PERCENTAGES")
                Spacer()
                Text(isBalanced ? "✓ 100%" : (remaining < 0
                    ? String(format: "%.0f%% over", abs(remaining))
                    : String(format: "%.0f%% left", remaining)))
                    .font(.nunito(12, weight: .bold))
                    .foregroundColor(isBalanced ? .appTerra : (remaining < 0 ? .red : .appMuted))
            }
            VStack(spacing: 8) {
                ForEach(participants) { member in
                    MemberPercentageRow(
                        member: member,
                        text: Binding(
                            get: { memberPercentages[member.id] ?? "" },
                            set: { memberPercentages[member.id] = $0 }
                        ),
                        totalAmount: parsedAmount
                    )
                }
            }
            if participants.count > 1 {
                splitActionRow(
                    fillAction: { fillPercentageEqually() },
                    clearAction: { memberPercentages = [:] }
                )
            }
        }
    }

    private func splitActionRow(fillAction: @escaping () -> Void, clearAction: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Button {
                fillAction()
                Haptics.selection()
            } label: {
                Text("Fill equally")
                    .font(.nunito(13, weight: .bold))
                    .foregroundColor(.appTerra)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.appTerra.opacity(0.5), lineWidth: 1.5)
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)

            Button {
                clearAction()
                Haptics.selection()
            } label: {
                Text("Clear all")
                    .font(.nunito(13, weight: .bold))
                    .foregroundColor(.appText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.appWarmGray, lineWidth: 1.5)
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 100)
        }
    }

    // MARK: - Remaining Sections

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Category")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                        categoryChip(cat)
                    }
                }
                .padding(.vertical, 2)
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
            sectionLabel("Date")
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
        VStack(alignment: .leading, spacing: 8) {
            if showNoteField || !note.isEmpty {
                sectionLabel("Note (optional)")
                TextField("Receipt details, location…", text: $note, axis: .vertical)
                    .font(.nunito(15, weight: .semibold))
                    .foregroundColor(.appText)
                    .lineLimit(3...6)
                    .focused($focus, equals: .note)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.appWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appBorder, lineWidth: 1.5)
                    )
                    .cornerRadius(12)
            } else {
                Button {
                    showNoteField = true
                    focus = .note
                } label: {
                    Text("Add note")
                        .font(.nunito(14, weight: .heavy))
                        .foregroundColor(.appTerra)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(11, weight: .heavy))
            .foregroundColor(.appMuted)
            .tracking(0.8)
    }

    // MARK: - Helpers

    private func resetSplitInputs() {
        memberAmounts = [:]
        memberPercentages = [:]
    }

    private func fillEqually() {
        guard parsedAmount > 0, !selectedParticipants.isEmpty else { return }
        let share = parsedAmount / Double(selectedParticipants.count)
        for id in selectedParticipants {
            memberAmounts[id] = String(format: "%.2f", share)
        }
    }

    private func fillPercentageEqually() {
        guard !selectedParticipants.isEmpty else { return }
        let ids = Array(selectedParticipants)
        let count = ids.count
        let basePct = floor(1000.0 / Double(count)) / 10.0
        var totalAssigned = 0.0
        for (i, id) in ids.enumerated() {
            if i == count - 1 {
                memberPercentages[id] = String(format: "%.1f", 100.0 - totalAssigned)
            } else {
                memberPercentages[id] = String(format: "%.1f", basePct)
                totalAssigned += basePct
            }
        }
    }

    private func syncSplitFields(for kind: ExpenseSplitType) {
        let ids = orderedSelectedMembers.map(\.id)
        guard !ids.isEmpty else {
            memberPercentages = [:]
            memberAmounts = [:]
            return
        }
        switch kind {
        case .equal:
            break
        case .percentage:
            let ints = Self.equalIntegerPercents(count: ids.count)
            for (i, id) in ids.enumerated() {
                memberPercentages[id] = String(ints[i])
            }
        case .exactAmount:
            let cents = Int((parsedAmount * 100).rounded())
            guard cents > 0 else {
                memberAmounts = [:]
                return
            }
            let n = ids.count
            let base = cents / n
            let rem = cents % n
            for (idx, id) in ids.enumerated() {
                let c = idx == n - 1 ? base + rem : base
                memberAmounts[id] = String(format: "%.2f", Double(c) / 100)
            }
        }
    }

    private static func equalIntegerPercents(count: Int) -> [Int] {
        guard count > 0 else { return [] }
        let base = 100 / count
        let rem = 100 % count
        return (0..<count).map { i in base + (i < rem ? 1 : 0) }
    }

    // MARK: - Save

    private func saveAndDismiss() {
        guard isValid, let paidById else { return }

        let payload: ExpenseSplitPayload
        switch splitType {
        case .equal:
            payload = .equal(participantIds: orderedSelectedMembers.map(\.id))
        case .percentage:
            guard let parts = percentagePayload else { return }
            payload = .percentage(parts: parts)
        case .exactAmount:
            guard let parts = exactPayload else { return }
            payload = .exact(parts: parts)
        }

        if let expenseId {
            viewModel.updateExpense(
                groupId: groupId,
                expenseId: expenseId,
                title: title.trimmingCharacters(in: .whitespaces),
                totalAmount: parsedAmount,
                paidByMemberId: paidById,
                splitType: splitType,
                category: category,
                date: date,
                note: note.isEmpty ? nil : note,
                splitPayload: payload
            )
        } else {
            viewModel.addExpense(
                toGroupId: groupId,
                title: title.trimmingCharacters(in: .whitespaces),
                totalAmount: parsedAmount,
                paidByMemberId: paidById,
                splitType: splitType,
                category: category,
                date: date,
                note: note.isEmpty ? nil : note,
                splitPayload: payload
            )
        }
        Haptics.success()
        dismiss()
    }
}

// MARK: - Row subviews
//
// Each row owns its text as @State (local buffer). The TextField only talks to
// that local state, so parent re-renders never recreate or reset the field.
// Two onChange handlers keep the two layers in sync:
//   • user types  → localText changes → write up to parent binding
//   • fill/clear  → parent binding changes → read down into localText

private struct MemberAmountRow: View {
    let member: Member
    @Binding var text: String
    @State private var localText: String

    init(member: Member, text: Binding<String>) {
        self.member = member
        self._text = text
        self._localText = State(initialValue: text.wrappedValue)
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: member.name, size: 36)
            Text(member.name.components(separatedBy: " ").first ?? member.name)
                .font(.nunito(14, weight: .semibold))
                .foregroundColor(.appText)
            Spacer()
            HStack(spacing: 3) {
                Text("$")
                    .font(.nunito(15, weight: .bold))
                    .foregroundColor(.appMuted)
                TextField("0.00", text: $localText)
                    .font(.nunito(16, weight: .heavy))
                    .foregroundColor(.appText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .onChange(of: localText) { _, newValue in text = newValue }
                    .onChange(of: text) { _, newValue in if newValue != localText { localText = newValue } }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.appBg)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.appBorder, lineWidth: 1.5)
            )
            .cornerRadius(10)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appWhite)
        .cornerRadius(12)
    }
}

private struct MemberPercentageRow: View {
    let member: Member
    @Binding var text: String
    let totalAmount: Double
    @State private var localText: String

    init(member: Member, text: Binding<String>, totalAmount: Double) {
        self.member = member
        self._text = text
        self.totalAmount = totalAmount
        self._localText = State(initialValue: text.wrappedValue)
    }

    private var pct: Double { Double(localText) ?? 0 }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: member.name, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name.components(separatedBy: " ").first ?? member.name)
                    .font(.nunito(14, weight: .semibold))
                    .foregroundColor(.appText)
                // Always a Text (never conditional) so the VStack height is stable
                // and SwiftUI never tears down the sibling TextField.
                Text(totalAmount > 0 && pct > 0 ? String(format: "$%.2f", totalAmount * pct / 100) : " ")
                    .font(.nunito(11, weight: .semibold))
                    .foregroundColor(.appMuted)
            }
            Spacer()
            HStack(spacing: 3) {
                TextField("0", text: $localText)
                    .font(.nunito(16, weight: .heavy))
                    .foregroundColor(.appText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                    .onChange(of: localText) { _, newValue in text = newValue }
                    .onChange(of: text) { _, newValue in if newValue != localText { localText = newValue } }
                Text("%")
                    .font(.nunito(15, weight: .bold))
                    .foregroundColor(.appMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.appBg)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.appBorder, lineWidth: 1.5)
            )
            .cornerRadius(10)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appWhite)
        .cornerRadius(12)
    }
}
