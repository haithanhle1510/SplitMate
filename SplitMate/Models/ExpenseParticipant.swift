import Foundation

struct ExpenseParticipant: Codable, Hashable, Identifiable {
    var id: UUID { memberId }

    var memberId: UUID
    /// Set when `splitType == .percentage` on the parent expense.
    var percentage: Double?
    var owedAmount: Double
}
