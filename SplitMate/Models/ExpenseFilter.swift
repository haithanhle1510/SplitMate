import Foundation

struct ExpenseFilter: Equatable {
    var memberIds: Set<UUID> = []
    var unsettledOnly: Bool = false

    var isActive: Bool { !memberIds.isEmpty || unsettledOnly }

    static let empty = ExpenseFilter()

    func matches(_ expense: Expense) -> Bool {
        if !memberIds.isEmpty {
            let involved = Set([expense.paidByMemberId] + expense.participants.map(\.memberId))
            if !memberIds.isSubset(of: involved) { return false }
        }
        if unsettledOnly && expense.isFullySettled {
            return false
        }
        return true
    }
}
