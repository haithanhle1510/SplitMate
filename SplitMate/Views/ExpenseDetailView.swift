import SwiftUI

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    let expenseId: UUID

    @State private var showDeleteAlert = false

    private var group: SplitGroup? { viewModel.groups.first { $0.id == groupId } }
    private var expense: Expense? { group?.expenses.first { $0.id == expenseId } }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            if let expense, let group {
                content(expense: expense, group: group)
            } else {
                Text("Expense not found")
                    .foregroundColor(.appMuted)
                    .font(.nunito(15))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("Delete expense", systemImage: "trash")
                    }
                } label: {
                    Text("Edit")
                        .font(.nunito(15, weight: .semibold))
                        .foregroundColor(.appTerra)
                }
            }
        }
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteExpense(groupId: groupId, expenseId: expenseId)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this expense.")
        }
    }

    @ViewBuilder
    private func content(expense: Expense, group: SplitGroup) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header card
                VStack(alignment: .leading, spacing: 10) {
                    // Category badge
                    HStack(spacing: 6) {
                        Text(expense.category.emoji)
                            .font(.system(size: 14))
                        Text(expense.category.displayName)
                            .font(.nunito(13, weight: .heavy))
                            .foregroundColor(.appTerra)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appPeach)
                    .cornerRadius(20)

                    // Amount
                    Text(String(format: "$%.2f", expense.amount))
                        .font(.nunito(44, weight: .heavy))
                        .foregroundColor(.appTerra)

                    // Title
                    Text(expense.title)
                        .font(.nunito(20, weight: .heavy))
                        .foregroundColor(.appText)

                    // Payer row
                    if let payer = group.members.first(where: { $0.id == expense.paidBy }) {
                        HStack(spacing: 8) {
                            AvatarView(name: payer.name, size: 22)
                            Text("Paid by \(payer.name) · \(expense.date.shortFormatted)")
                                .font(.nunito(13, weight: .semibold))
                                .foregroundColor(.appMuted)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().background(Color.appBorder).padding(.horizontal, 16)

                // Settlement section
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Split equally")
                            .font(.nunito(15, weight: .heavy))
                            .foregroundColor(.appText)
                        Spacer()
                        settlementBadge(expense: expense)
                    }

                    ForEach(orderedParticipants(expense: expense, group: group), id: \.id) { member in
                        memberSettlementRow(member: member, expense: expense)
                    }
                }
                .padding(20)

                if let note = expense.note, !note.isEmpty {
                    Divider().background(Color.appBorder).padding(.horizontal, 16)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTE")
                            .font(.nunito(11, weight: .heavy))
                            .foregroundColor(.appMuted)
                            .tracking(0.8)
                        Text(note)
                            .font(.nunito(14, weight: .semibold))
                            .foregroundColor(.appText)
                    }
                    .padding(20)
                }
            }
            .background(Color.appWhite)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            .padding(16)
        }
    }

    private func settlementBadge(expense: Expense) -> some View {
        let settled = expense.settledCount
        let total = expense.participantIds.count
        return Text("\(settled)/\(total) settled")
            .font(.nunito(12, weight: .heavy))
            .foregroundColor(.appMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.appWarmGrayLt)
            .cornerRadius(20)
    }

    private func memberSettlementRow(member: Member, expense: Expense) -> some View {
        let isPayer = member.id == expense.paidBy
        let isSettled = expense.settledMemberIds.contains(member.id)
        let share = expense.perPersonShare

        return HStack(spacing: 12) {
            AvatarView(name: member.name, size: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(member.name)
                    .font(.nunito(15, weight: .bold))
                    .foregroundColor(.appText)
                if isPayer {
                    Text("Paid upfront")
                        .font(.nunito(11, weight: .bold))
                        .foregroundColor(.appTerra)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.appPeach)
                        .cornerRadius(8)
                }
            }

            Spacer()

            Text(String(format: "$%.2f", share))
                .font(.nunito(15, weight: .bold))
                .foregroundColor(.appText)

            Button {
                if !isPayer {
                    viewModel.toggleSettlement(groupId: groupId, expenseId: expenseId, memberId: member.id)
                    Haptics.selection()
                }
            } label: {
                Text(isSettled ? "Paid" : "Unpaid")
                    .font(.nunito(12, weight: .heavy))
                    .foregroundColor(isSettled ? Color(hex: 0x4A8A44) : .appMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isSettled ? Color.appSageLt : Color.appWarmGrayLt)
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .disabled(isPayer)
        }
        .padding(.vertical, 4)
    }

    // Payer always first, then remaining participants in original order
    private func orderedParticipants(expense: Expense, group: SplitGroup) -> [Member] {
        let participantSet = Set(expense.participantIds)
        let participants = group.members.filter { participantSet.contains($0.id) }
        let payer = participants.filter { $0.id == expense.paidBy }
        let others = participants.filter { $0.id != expense.paidBy }
        return payer + others
    }
}