import Foundation

struct Expense: Identifiable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var paidBy: UUID
    var participantIds: [UUID]
    var category: ExpenseCategory
    var date: Date
    var note: String?
    // The payer's own share is considered settled on creation; only the
    // remaining participants need to reimburse them.
    var settledMemberIds: [UUID]

    var isFullySettled: Bool {
        participantIds.allSatisfy { settledMemberIds.contains($0) }
    }

    var perPersonShare: Double {
        guard !participantIds.isEmpty else { return 0 }
        return amount / Double(participantIds.count)
    }

    // Total still owed to the payer (sum of shares from unsettled participants)
    var unsettledAmount: Double {
        let unsettledCount = participantIds.filter { !settledMemberIds.contains($0) }.count
        return perPersonShare * Double(unsettledCount)
    }

    var settledCount: Int { participantIds.filter { settledMemberIds.contains($0) }.count }
}
