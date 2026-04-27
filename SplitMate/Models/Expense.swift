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
    var isSettled: Bool
}
