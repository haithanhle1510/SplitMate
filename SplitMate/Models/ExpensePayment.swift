import Foundation

struct ExpensePayment: Codable, Hashable, Identifiable {
    var id: UUID
    var paidByMemberId: UUID
    var paidToMemberId: UUID
    var amount: Double
    var recordedAt: Date
}
