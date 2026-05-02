import Foundation

struct SplitGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var members: [Member]
    var expenses: [Expense]
    var createdAt: Date
}
