import Foundation

struct Expense: Identifiable, Codable {
    static let balanceEpsilon = 0.02

    let id: UUID
    var title: String
    var totalAmount: Double
    var paidByMemberId: UUID
    var splitType: ExpenseSplitType
    var participants: [ExpenseParticipant]
    var payments: [ExpensePayment]
    var category: ExpenseCategory
    var date: Date
    var note: String?
    var createdAt: Date

    func participantRow(for memberId: UUID) -> ExpenseParticipant? {
        participants.first { $0.memberId == memberId }
    }

    /// Payments from `memberId` toward the person who paid for this expense.
    func totalPaidTowardPayer(from memberId: UUID) -> Double {
        payments
            .filter { $0.paidByMemberId == memberId && $0.paidToMemberId == paidByMemberId }
            .reduce(0) { $0 + $1.amount }
    }

    /// Refunds from the payer back to a participant (reduces overpayment).
    func totalRepaidByPayer(to participantId: UUID) -> Double {
        payments
            .filter { $0.paidByMemberId == paidByMemberId && $0.paidToMemberId == participantId }
            .reduce(0) { $0 + $1.amount }
    }

    /// For a non-payer: `owed - paid to payer + repaid by payer`. Positive still owes; negative net overpaid; zero square.
    func signedBalanceTowardPayer(memberId: UUID) -> Double {
        guard memberId != paidByMemberId else { return 0 }
        guard let row = participantRow(for: memberId) else { return 0 }
        let forward = row.owedAmount - totalPaidTowardPayer(from: memberId)
        return forward + totalRepaidByPayer(to: memberId)
    }

    /// Max additional payment participant can send toward payer (based on owed vs forward payments only).
    func maxAdditionalPaymentTowardPayer(memberId: UUID) -> Double {
        guard memberId != paidByMemberId,
              let row = participantRow(for: memberId) else { return 0 }
        return max(0, row.owedAmount - totalPaidTowardPayer(from: memberId))
    }

    /// Max payer can still return to erase uncredited overpay for this participant.
    func maxRepaymentFromPayer(to participantId: UUID) -> Double {
        guard participantId != paidByMemberId,
              let row = participantRow(for: participantId) else { return 0 }
        let over = totalPaidTowardPayer(from: participantId) - row.owedAmount
        return max(0, over - totalRepaidByPayer(to: participantId))
    }

    /// Still owed to payer by non-payers (positive remainders toward payer).
    var unsettledAmount: Double {
        participants
            .filter { $0.memberId != paidByMemberId }
            .reduce(0) { $0 + max(0, signedBalanceTowardPayer(memberId: $1.memberId)) }
    }

    var isFullySettled: Bool {
        participants
            .filter { $0.memberId != paidByMemberId }
            .allSatisfy { abs(signedBalanceTowardPayer(memberId: $0.memberId)) <= Self.balanceEpsilon }
    }

}
