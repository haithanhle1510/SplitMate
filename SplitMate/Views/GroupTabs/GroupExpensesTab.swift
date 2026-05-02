import SwiftUI

struct GroupExpensesTab: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @State private var showingComingSoon = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            EmptyStateView(
                emoji: "🧾",
                title: "No expenses yet.",
                message: "Adding expenses is coming soon.",
                ctaLabel: "+ Add expense",
                onCtaTap: { showingComingSoon = true }
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingComingSoon = true
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
        .alert("Coming soon", isPresented: $showingComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The Add Expense flow is still being built. Check back soon.")
        }
    }
}
