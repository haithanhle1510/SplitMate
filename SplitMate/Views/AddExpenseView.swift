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
    @State private var percentageField: [UUID: String] = [:]
    @State private var exactField: [UUID: String] = [:]
    @State private var category: ExpenseCategory = .food
    @State private var date = Date()
    @State private var note = ""
    @State private var showNoteField = false
    /// Lets initial edit hydration finish before `splitType` / participant `onChange` overwrites percentage/exact fields.
    @State private var hasCompletedInitialLoad = false

    @FocusState private var focus: AddExpenseFocus?

    private enum AddExpenseFocus: Hashable {
        case title, amount, note
    }

    /// Matches `GroupViewModel` percentage sum check.
    private static let percentageSumEpsilon = 0.5
    /// Matches `GroupViewModel.splitMoneyEpsilon`.
    private static let exactSumEpsilon = 0.02

    private var group: SplitGroup? { viewModel.groups.first { $0.id == groupId } }

    private var isEditMode: Bool { expenseId != nil }

    private var parsedAmount: Double { Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private var orderedSelectedMembers: [Member] {
        guard let group else { return [] }
        return group.members.filter { selectedParticipants.contains($0.id) }
    }

    private var percentagePayload: [(memberId: UUID, percentage: Double)]? {
        let members = orderedSelectedMembers
        guard members.count == selectedParticipants.count else { return nil }
        var parts: [(UUID, Double)] = []
        for m in members {
            guard let raw = percentageField[m.id]?.trimmingCharacters(in: .whitespaces),
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
            guard let raw = exactField[m.id]?.trimmingCharacters(in: .whitespaces),
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
        case .equal:
            return true
        case .percentage:
            return percentagePayload != nil
        case .exactAmount:
            return exactPayload != nil
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
                            amountSection
                            splitTypeSection
                            if let group {
                                paidBySection(group: group)
                                participantsSection(group: group)
                            }
                            if splitType == .percentage {
                                percentageSplitSection
                            }
                            if splitType == .exactAmount {
                                exactSplitSection
                            }
                            splitSummaryBlock
                            categorySection
                            dateSection
                            noteSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    }
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focus = nil }
                        .font(.nunito(16, weight: .semibold))
                        .foregroundColor(.appTerra)
                }
            }
            .onAppear {
                if let id = expenseId {
                    hydrateForEdit(expenseId: id)
                    DispatchQueue.main.async {
                        hasCompletedInitialLoad = true
                    }
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

    private func applyCreateModeDefaults() {
        guard let g = viewModel.groups.first(where: { $0.id == groupId }) else { return }
        if selectedParticipants.isEmpty {
            selectedParticipants = Set(g.members.map(\.id))
        }
        if !note.isEmpty {
            showNoteField = true
        }
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
        percentageField = [:]
        exactField = [:]
        switch expense.splitType {
        case .equal:
            break
        case .percentage:
            for p in expense.participants {
                guard let pct = p.percentage else { continue }
                if abs(pct - pct.rounded()) < 0.001 {
                    percentageField[p.memberId] = String(format: "%.0f", pct)
                } else {
                    percentageField[p.memberId] = String(format: "%g", pct)
                }
            }
        case .exactAmount:
            for p in expense.participants {
                exactField[p.memberId] = String(format: "%.2f", p.owedAmount)
            }
        }
    }

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

    private var splitSummaryLines: [String] {
        let count = selectedParticipants.count
        switch splitType {
        case .equal:
            guard count > 0, parsedAmount > 0 else {
                return ["Enter an amount and keep at least one person in the split."]
            }
            let each = parsedAmount / Double(count)
            return [String(format: "$%.2f each · %d %@", each, count, count == 1 ? "person" : "people")]
        case .percentage:
            guard count > 0, parsedAmount > 0 else {
                return ["Enter an amount and select who splits."]
            }
            if percentagePayload != nil {
                return ["Percentages add to 100%."]
            }
            let sum = orderedSelectedMembers.compactMap { m -> Double? in
                guard let t = percentageField[m.id] else { return nil }
                return Double(t.replacingOccurrences(of: ",", with: "."))
            }.reduce(0, +)
            return [String(format: "Entered %.0f%% of 100%", sum)]
        case .exactAmount:
            guard count > 0, parsedAmount > 0 else {
                return ["Enter an amount and select who splits."]
            }
            if exactPayload != nil {
                return ["Amounts add up to the total."]
            }
            let sum = orderedSelectedMembers.compactMap { m -> Double? in
                guard let t = exactField[m.id] else { return nil }
                return Double(t.replacingOccurrences(of: ",", with: "."))
            }.reduce(0, +)
            return [String(format: "Entered %@ of %@", CurrencyFormatter.format(sum), CurrencyFormatter.format(parsedAmount))]
        }
    }

    private var splitSummaryBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(splitSummaryLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(.appMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var splitTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Split type")
            Picker("Split type", selection: $splitType) {
                ForEach(ExpenseSplitType.allCases, id: \.self) { kind in
                    Text(kind.displayLabel).tag(kind)
                }
            }
            .pickerStyle(.menu)
            .font(.nunito(15, weight: .semibold))
            .foregroundColor(.appText)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appWhite)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appBorder, lineWidth: 1.5)
            )
            .cornerRadius(12)
        }
    }

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

    private var percentageSplitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Percentages (total 100%)")
            ForEach(orderedSelectedMembers) { member in
                HStack {
                    Text(member.name.components(separatedBy: " ").first ?? member.name)
                        .font(.nunito(14, weight: .semibold))
                        .foregroundColor(.appText)
                    Spacer()
                    TextField("0", text: Binding(
                        get: { percentageField[member.id] ?? "" },
                        set: { percentageField[member.id] = $0 }
                    ))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.nunito(15, weight: .heavy))
                    .frame(width: 56)
                    Text("%")
                        .font(.nunito(13, weight: .semibold))
                        .foregroundColor(.appMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.appWhite)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1.5))
                .cornerRadius(12)
            }
        }
    }

    private var exactSplitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Amounts (must match total)")
            ForEach(orderedSelectedMembers) { member in
                HStack {
                    Text(member.name.components(separatedBy: " ").first ?? member.name)
                        .font(.nunito(14, weight: .semibold))
                        .foregroundColor(.appText)
                    Spacer()
                    Text("$")
                        .font(.nunito(14, weight: .heavy))
                    TextField("0.00", text: Binding(
                        get: { exactField[member.id] ?? "" },
                        set: { exactField[member.id] = $0 }
                    ))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.nunito(15, weight: .heavy))
                    .frame(width: 88)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.appWhite)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1.5))
                .cornerRadius(12)
            }
        }
    }

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
            .tracking(0.4)
    }

    private func syncSplitFields(for kind: ExpenseSplitType) {
        let ids = orderedSelectedMembers.map(\.id)
        guard !ids.isEmpty else {
            percentageField = [:]
            exactField = [:]
            return
        }

        switch kind {
        case .equal:
            break
        case .percentage:
            let ints = Self.equalIntegerPercents(count: ids.count)
            for (i, id) in ids.enumerated() {
                percentageField[id] = String(ints[i])
            }
        case .exactAmount:
            let cents = Int((parsedAmount * 100).rounded())
            guard cents > 0 else {
                exactField = [:]
                return
            }
            let n = ids.count
            let base = cents / n
            let rem = cents % n
            for (idx, id) in ids.enumerated() {
                let c = idx == n - 1 ? base + rem : base
                exactField[id] = String(format: "%.2f", Double(c) / 100)
            }
        }
    }

    private static func equalIntegerPercents(count: Int) -> [Int] {
        guard count > 0 else { return [] }
        let base = 100 / count
        let rem = 100 % count
        return (0..<count).map { i in base + (i < rem ? 1 : 0) }
    }

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
