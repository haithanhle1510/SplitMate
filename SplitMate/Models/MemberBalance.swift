import Foundation

struct MemberBalance: Identifiable {
    let id: UUID
    let member: Member
    var balance: Double     // Positive = owed, Negative = owes
    let debts: [Debt]       // All debts involving this member (as debtor or creditor)
}
