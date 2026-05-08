import SwiftUI

struct ExpenseMiniRow: View {
    let expense: Expense
    
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
                Text(expense.date.shortFormatted)
                    .font(.nunito(11, weight: .semibold))
                    .foregroundColor(.appMuted)
            }
            Spacer()
            Text(String(format: "$%.2f", expense.perPersonShare))
                .font(.nunito(13, weight: .bold))
                .foregroundColor(.appTerra)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

#Preview {
    let sample = Expense(
        id: UUID(),
        title: "Dinner",
        amount: 120,
        paidBy: UUID(),
        participantIds: [UUID(), UUID(), UUID()],
        category: .food,
        date: Date(),
        note: nil,
        settledMemberIds: []
    )
    return ExpenseMiniRow(expense: sample)
}
