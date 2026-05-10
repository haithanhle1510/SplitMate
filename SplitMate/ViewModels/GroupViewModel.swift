import Foundation
import Combine
import SwiftUI

enum RemoveMemberResult {
    case removed
    case blockedByExpenses
    case notFound
}

private let splitMoneyEpsilon = 0.02

class GroupViewModel: ObservableObject {
    @Published var groups: [SplitGroup] = [] {
        didSet { GroupStorageService.shared.save(groups: groups) }
    }

    init() {
        self.groups = GroupStorageService.shared.load()
    }

    @discardableResult
    func addGroup(name: String) -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let id = UUID()
        guard !trimmed.isEmpty else { return id }
        let group = SplitGroup(id: id, name: trimmed, members: [], expenses: [], createdAt: Date())
        groups.append(group)
        return id
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
            exp.paidByMemberId == memberId || exp.participants.contains(where: { $0.memberId == memberId })
        }
        if isReferencedInExpenses {
            return .blockedByExpenses
        }
        groups[idx].members.removeAll { $0.id == memberId }
        return .removed
    }

    // MARK: - Expenses

    func addExpense(
        toGroupId: UUID,
        title: String,
        totalAmount: Double,
        paidByMemberId: UUID,
        splitType: ExpenseSplitType,
        category: ExpenseCategory,
        date: Date,
        note: String?,
        splitPayload: ExpenseSplitPayload
    ) {
        guard let idx = groups.firstIndex(where: { $0.id == toGroupId }) else { return }
        guard totalAmount > 0 else { return }

        guard let participants = Self.makeParticipants(
            totalAmount: totalAmount,
            paidByMemberId: paidByMemberId,
            splitType: splitType,
            payload: splitPayload
        ) else { return }

        let expense = Expense(
            id: UUID(),
            title: title,
            totalAmount: totalAmount,
            paidByMemberId: paidByMemberId,
            splitType: splitType,
            participants: participants,
            payments: [],
            category: category,
            date: date,
            note: note?.isEmpty == false ? note : nil,
            createdAt: Date()
        )
        groups[idx].expenses.insert(expense, at: 0)
    }

    func deleteExpense(groupId: UUID, expenseId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].expenses.removeAll { $0.id == expenseId }
    }

    func updateExpense(
        groupId: UUID,
        expenseId: UUID,
        title: String,
        totalAmount: Double,
        paidByMemberId: UUID,
        splitType: ExpenseSplitType,
        category: ExpenseCategory,
        date: Date,
        note: String?,
        splitPayload: ExpenseSplitPayload
    ) {
        guard let gIdx = groups.firstIndex(where: { $0.id == groupId }),
              let eIdx = groups[gIdx].expenses.firstIndex(where: { $0.id == expenseId }) else { return }
        guard totalAmount > 0 else { return }

        guard let participants = Self.makeParticipants(
            totalAmount: totalAmount,
            paidByMemberId: paidByMemberId,
            splitType: splitType,
            payload: splitPayload
        ) else { return }

        let participantIds = Set(participants.map(\.memberId))
        let old = groups[gIdx].expenses[eIdx]
        let retainedPayments = old.payments.filter { payment in
            let fwd = payment.paidToMemberId == paidByMemberId
                && participantIds.contains(payment.paidByMemberId)
            let rev = payment.paidByMemberId == paidByMemberId
                && participantIds.contains(payment.paidToMemberId)
            return fwd || rev
        }

        groups[gIdx].expenses[eIdx] = Expense(
            id: old.id,
            title: title,
            totalAmount: totalAmount,
            paidByMemberId: paidByMemberId,
            splitType: splitType,
            participants: participants,
            payments: retainedPayments,
            category: category,
            date: date,
            note: note?.isEmpty == false ? note : nil,
            createdAt: old.createdAt
        )
    }

    /// Participant → payer settlement, or payer → participant refund when someone overpaid.
    func addPayment(
        groupId: UUID,
        expenseId: UUID,
        paidByMemberId: UUID,
        paidToMemberId: UUID,
        amount: Double
    ) {
        guard amount > 0 else { return }
        guard let gIdx = groups.firstIndex(where: { $0.id == groupId }),
              let eIdx = groups[gIdx].expenses.firstIndex(where: { $0.id == expenseId }) else { return }
        guard paidByMemberId != paidToMemberId else { return }

        let payerId = groups[gIdx].expenses[eIdx].paidByMemberId
        let snapshot = groups[gIdx].expenses[eIdx]

        if paidToMemberId == payerId, paidByMemberId != payerId {
            guard snapshot.participantRow(for: paidByMemberId) != nil else { return }
            let maxPay = snapshot.maxAdditionalPaymentTowardPayer(memberId: paidByMemberId)
            guard amount <= maxPay + splitMoneyEpsilon else { return }
        } else if paidByMemberId == payerId, paidToMemberId != payerId {
            guard snapshot.participantRow(for: paidToMemberId) != nil else { return }
            let maxRepay = snapshot.maxRepaymentFromPayer(to: paidToMemberId)
            guard amount <= maxRepay + splitMoneyEpsilon else { return }
        } else {
            return
        }

        appendPayment(
            on: &groups[gIdx].expenses[eIdx],
            paidBy: paidByMemberId,
            paidTo: paidToMemberId,
            amount: amount
        )
    }

    /// One payment per expense for each direction: participant→payer when still owed, payer→participant when overpaid.
    func settleBetweenPair(groupId: UUID, memberA: UUID, memberB: UUID) {
        guard let gIdx = groups.firstIndex(where: { $0.id == groupId }) else { return }

        for eIdx in groups[gIdx].expenses.indices {
            let expSnapshot = groups[gIdx].expenses[eIdx]

            if expSnapshot.paidByMemberId == memberA,
               expSnapshot.participantRow(for: memberB) != nil {
                let rem = groups[gIdx].expenses[eIdx].signedBalanceTowardPayer(memberId: memberB)
                if rem > splitMoneyEpsilon {
                    appendPayment(on: &groups[gIdx].expenses[eIdx], paidBy: memberB, paidTo: memberA, amount: rem)
                } else if rem < -splitMoneyEpsilon {
                    appendPayment(on: &groups[gIdx].expenses[eIdx], paidBy: memberA, paidTo: memberB, amount: -rem)
                }
            }
            if expSnapshot.paidByMemberId == memberB,
               expSnapshot.participantRow(for: memberA) != nil {
                let rem = groups[gIdx].expenses[eIdx].signedBalanceTowardPayer(memberId: memberA)
                if rem > splitMoneyEpsilon {
                    appendPayment(on: &groups[gIdx].expenses[eIdx], paidBy: memberA, paidTo: memberB, amount: rem)
                } else if rem < -splitMoneyEpsilon {
                    appendPayment(on: &groups[gIdx].expenses[eIdx], paidBy: memberB, paidTo: memberA, amount: -rem)
                }
            }
        }
    }

    private func appendPayment(on expense: inout Expense, paidBy: UUID, paidTo: UUID, amount: Double) {
        expense.payments.append(
            ExpensePayment(
                id: UUID(),
                paidByMemberId: paidBy,
                paidToMemberId: paidTo,
                amount: amount,
                recordedAt: Date()
            )
        )
    }

    // MARK: - Reads

    func pairwiseNetDebts(groupId: UUID) -> [Debt] {
        guard let group = groups.first(where: { $0.id == groupId }) else { return [] }
        return BalanceCalculatorService.calculatePairwiseNetDebts(group)
    }

    func pairContributions(groupId: UUID, debtor: Member, creditor: Member) -> [PairContribution] {
        guard let group = groups.first(where: { $0.id == groupId }) else { return [] }
        return BalanceCalculatorService.pairContributions(group: group, debtor: debtor, creditor: creditor)
    }

    func totalSpent(groupId: UUID) -> Double {
        guard let group = groups.first(where: { $0.id == groupId }) else { return 0 }
        return group.expenses.reduce(0) { $0 + $1.totalAmount }
    }

    // MARK: - Split math

    private static func makeParticipants(
        totalAmount: Double,
        paidByMemberId: UUID,
        splitType: ExpenseSplitType,
        payload: ExpenseSplitPayload
    ) -> [ExpenseParticipant]? {
        switch splitType {
        case .equal:
            guard case .equal(let ids) = payload else { return nil }
            guard !ids.isEmpty, ids.contains(paidByMemberId) else { return nil }
            return distributeEqual(totalAmount: totalAmount, paidByMemberId: paidByMemberId, participantIds: ids)

        case .percentage:
            guard case .percentage(let parts) = payload else { return nil }
            guard !parts.isEmpty, parts.contains(where: { $0.memberId == paidByMemberId }) else { return nil }
            let sumPct = parts.reduce(0) { $0 + $1.percentage }
            guard abs(sumPct - 100) < 0.5 else { return nil }
            return distributePercentage(totalAmount: totalAmount, paidByMemberId: paidByMemberId, parts: parts)

        case .exactAmount:
            guard case .exact(let parts) = payload else { return nil }
            guard !parts.isEmpty, parts.contains(where: { $0.memberId == paidByMemberId }) else { return nil }
            let sumAmt = parts.reduce(0) { $0 + $1.amount }
            guard abs(sumAmt - totalAmount) < splitMoneyEpsilon else { return nil }
            return parts.map { id, amt in
                ExpenseParticipant(memberId: id, percentage: nil, owedAmount: amt)
            }
        }
    }

    /// Last participant absorbs cent remainder so the row sums match `totalAmount`.
    private static func distributeEqual(
        totalAmount: Double,
        paidByMemberId: UUID,
        participantIds: [UUID]
    ) -> [ExpenseParticipant] {
        let n = participantIds.count
        guard n > 0 else { return [] }
        let totalCents = Int((totalAmount * 100).rounded())
        let base = totalCents / n
        let rem = totalCents % n
        return participantIds.enumerated().map { idx, id in
            let cents = idx == n - 1 ? base + rem : base
            return ExpenseParticipant(
                memberId: id,
                percentage: nil,
                owedAmount: Double(cents) / 100
            )
        }
    }

    private static func distributePercentage(
        totalAmount: Double,
        paidByMemberId: UUID,
        parts: [(memberId: UUID, percentage: Double)]
    ) -> [ExpenseParticipant] {
        let totalCents = Int((totalAmount * 100).rounded())
        var allocated = 0
        var result: [ExpenseParticipant] = []
        for i in parts.indices {
            let (memberId, pct) = parts[i]
            let cents: Int
            if i == parts.count - 1 {
                cents = max(0, totalCents - allocated)
            } else {
                cents = Int((Double(totalCents) * pct / 100.0).rounded())
                allocated += cents
            }
            result.append(
                ExpenseParticipant(
                    memberId: memberId,
                    percentage: pct,
                    owedAmount: Double(cents) / 100
                )
            )
        }
        return result
    }
}
