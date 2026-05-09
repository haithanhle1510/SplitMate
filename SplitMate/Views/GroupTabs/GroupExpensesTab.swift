import SwiftUI

struct GroupExpensesTab: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @Binding var showingAddExpense: Bool

    private var group: SplitGroup? { viewModel.groups.first { $0.id == groupId } }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            if let group {
                if group.expenses.isEmpty {
                    emptyState
                } else {
                    expenseList(group: group)
                }
            }
        }
    }

    //Empty state
    private var emptyState: some View {
        EmptyStateView(
            emoji: "🧾",
            title: "No expenses yet.",
            message: "First round on you?",
            ctaLabel: "+ Add expense",
            onCtaTap: { showingAddExpense = true }
        )
    }

    //Expense list
    private func expenseList(group: SplitGroup) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(group.expenses) { expense in
                    NavigationLink {
                        ExpenseDetailView(viewModel: viewModel, groupId: groupId, expenseId: expense.id)
                            .navigationTitle(expense.title)
                    } label: {
                        ExpenseRowView(expense: expense, group: group)
                    }
                    .buttonStyle(.plain)

                    if expense.id != group.expenses.last?.id {
                        Divider()
                            .background(Color.appBorder)
                            .padding(.leading, 68)
                    }
                }
            }
            .background(Color.appWhite)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

//Expense Row
struct ExpenseRowView: View {
    let expense: Expense
    let group: SplitGroup

    private var payerName: String {
        group.members.first { $0.id == expense.paidBy }?.name ?? "Unknown"
    }

    private var splitInfo: String {
        let count = expense.participantIds.count
        let ways = count == 1 ? "solo" : "split \(count) ways"
        return "Paid by \(payerName) · $\(Int(expense.amount)) · \(ways)"
    }

    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Color.appPeach)
                    .frame(width: 44, height: 44)
                Text(expense.category.emoji)
                    .font(.system(size: 20))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.nunito(15, weight: .heavy))
                    .foregroundColor(.appText)
                Text(splitInfo)
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(.appMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Amount + date
            VStack(alignment: .trailing, spacing: 3) {
                if expense.isFullySettled {
                    Text("settled")
                        .font(.nunito(13, weight: .heavy))
                        .foregroundColor(.appSageDark)
                } else {
                    Text(String(format: "$%.2f unsettled", expense.unsettledAmount))
                        .font(.nunito(13, weight: .heavy))
                        .foregroundColor(.appTerra)
                }
                Text(expense.date.shortFormatted)
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(.appMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
