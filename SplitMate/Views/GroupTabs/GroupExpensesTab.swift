import SwiftUI

struct GroupExpensesTab: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            EmptyStateView(
                emoji: "🧾",
                title: "No expenses yet.",
                message: "First round on you?",
                ctaLabel: "+ Add expense",
                onCtaTap: {
                    // Add Expense flow not yet built — placeholder for future work.
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Add Expense flow not yet built — placeholder for future work.
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9).fill(Color.appTerra)
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .frame(width: 30, height: 30)
                }
                .accessibilityLabel("Add expense")
            }
        }
    }
}
