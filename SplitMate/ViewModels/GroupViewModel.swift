import Foundation
import Combine

enum RemoveMemberResult {
    case removed
    case blockedByExpenses
    case notFound
}

class GroupViewModel: ObservableObject {
    @Published var groups: [SplitGroup] = [] {
        didSet { GroupStorageService.shared.save(groups: groups) }
    }

    init() {
        self.groups = GroupStorageService.shared.load()
    }

    func addGroup(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let group = SplitGroup(id: UUID(), name: trimmed, members: [], expenses: [], createdAt: Date())
        groups.append(group)
    }

    func renameGroup(id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let idx = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[idx].name = trimmed
    }

    func deleteGroup(id: UUID) {
        groups.removeAll { $0.id == id }
    }

    func addMember(toGroupId: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let idx = groups.firstIndex(where: { $0.id == toGroupId }) else { return }
        groups[idx].members.append(Member(id: UUID(), name: trimmed))
    }

    func removeMember(fromGroupId: UUID, memberId: UUID) -> RemoveMemberResult {
        guard let idx = groups.firstIndex(where: { $0.id == fromGroupId }) else {
            return .notFound
        }
        let isReferencedInExpenses = groups[idx].expenses.contains { exp in
            exp.paidBy == memberId || exp.participantIds.contains(memberId)
        }
        if isReferencedInExpenses {
            return .blockedByExpenses
        }
        groups[idx].members.removeAll { $0.id == memberId }
        return .removed
    }

    //Expenses
    func addExpense(
        toGroupId: UUID,
        title: String,
        amount: Double,
        paidBy: UUID,
        participantIds: [UUID],
        category: ExpenseCategory,
        date: Date,
        note: String?
    ) {
        guard let idx = groups.firstIndex(where: { $0.id == toGroupId }) else { return }
        let expense = Expense(
            id: UUID(),
            title: title,
            amount: amount,
            paidBy: paidBy,
            participantIds: participantIds,
            category: category,
            date: date,
            note: note?.isEmpty == false ? note : nil,
            settledMemberIds: [paidBy]
        )
        // Insert at front so the list always shows newest expense first without sorting.
        groups[idx].expenses.insert(expense, at: 0)
    }

    func deleteExpense(groupId: UUID, expenseId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].expenses.removeAll { $0.id == expenseId }
    }

    func toggleSettlement(groupId: UUID, expenseId: UUID, memberId: UUID) {
        guard let gIdx = groups.firstIndex(where: { $0.id == groupId }),
              let eIdx = groups[gIdx].expenses.firstIndex(where: { $0.id == expenseId }) else { return }
        let expense = groups[gIdx].expenses[eIdx]
        guard memberId != expense.paidBy else { return }
        if expense.settledMemberIds.contains(memberId) {
            groups[gIdx].expenses[eIdx].settledMemberIds.removeAll { $0 == memberId }
        } else {
            groups[gIdx].expenses[eIdx].settledMemberIds.append(memberId)
        }
    }

    // MARK: - Debt Calculations
    
    /// Get direct debts (original debts from expenses, no simplification)
    func groupDirectDebts(groupId: UUID) -> [Debt] {
        guard let group = groups.first(where: { $0.id == groupId }) else { return [] }
        return BalanceCalculatorService.calculateDirectDebts(group)
    }
    
    /// Get simplified debts (using greedy algorithm - RECOMMENDED)
    func groupSimplifiedDebts(groupId: UUID) -> [Debt] {
        guard let group = groups.first(where: { $0.id == groupId }) else { return [] }
        return BalanceCalculatorService.calculateSimplifiedDebts(group)
    }
    
    /// Get all debts in a group (who owes who) - backward compatible
    func groupDebts(groupId: UUID) -> [Debt] {
        return groupSimplifiedDebts(groupId: groupId)
    }
    
    /// Get expenses for a specific debt
    func getExpensesForDebt(_ debt: Debt, groupId: UUID) -> [Expense] {
        guard let group = groups.first(where: { $0.id == groupId }) else { return [] }
        return BalanceCalculatorService.getExpensesForDebt(debt, group: group)
    }
    
    /// Get member balances for a group
    func memberBalances(groupId: UUID) -> [MemberBalance] {
        guard let group = groups.first(where: { $0.id == groupId }) else { return [] }
        return BalanceCalculatorService.calculateMemberBalances(group)
    }
}
