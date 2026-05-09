import Foundation

struct Debt: Identifiable {
    let id: UUID = UUID()
    let debtor: Member      // Person who owes
    let creditor: Member    // Person who is owed
    var amount: Double      // Amount owed
    var expenseIds: [UUID] = []  // Which expenses contribute to this debt
}
