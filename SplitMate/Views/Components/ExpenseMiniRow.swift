import SwiftUI

struct ExpenseMiniRow: View {
    let expense: Expense
    let paidByName: String?

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.appPeach)
                    .frame(width: 44, height: 44)
                Text(expense.category.emoji)
                    .font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.nunito(13, weight: .bold))
                    .foregroundColor(.appText)
                HStack(spacing: 4) {
                    Text(expense.date.shortFormatted)
                        .font(.nunito(10, weight: .semibold))
                        .foregroundColor(.appMuted)
                    if let paidByName {
                        Text("• Paid by \(paidByName)")
                            .font(.nunito(10, weight: .semibold))
                            .foregroundColor(.appMuted)
                    }
                }
            }
            Spacer()
            Text(String(format: "$%.2f", expense.totalAmount))
                .font(.nunito(13, weight: .bold))
                .foregroundColor(.appTerra)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

#Preview {
    let idA = UUID()
    let idB = UUID()
    let sample = Expense(
        id: UUID(),
        title: "Dinner",
        totalAmount: 120,
        paidByMemberId: idA,
        splitType: .equal,
        participants: [
            ExpenseParticipant(memberId: idA, percentage: nil, owedAmount: 60),
            ExpenseParticipant(memberId: idB, percentage: nil, owedAmount: 60)
        ],
        payments: [],
        category: .food,
        date: Date(),
        note: nil,
        createdAt: Date()
    )
    return ExpenseMiniRow(expense: sample, paidByName: "Alex")
}
