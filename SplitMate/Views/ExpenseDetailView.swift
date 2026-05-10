import SwiftUI

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    let expenseId: UUID

    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var settleIntent: ExpenseSettleIntent?

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
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit expense", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("Delete expense", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.appTerra)
                }
                .accessibilityLabel("More options")
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddExpenseView(viewModel: viewModel, groupId: groupId, expenseId: expenseId)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert(
            "Settle",
            isPresented: Binding(
                get: { settleIntent != nil },
                set: { if !$0 { settleIntent = nil } }
            ),
            presenting: settleIntent,
            actions: { intent in
                Button("Cancel", role: .cancel) {}
                Button("Settle") {
                    commitSettle(intent)
                    Haptics.selection()
                }
            },
            message: { intent in
                Text(settleAlertMessage(for: intent))
            }
        )
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
        let payerName = group.members.first { $0.id == expense.paidByMemberId }?.name ?? "Member"

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(expense.category.emoji) \(expense.category.displayName)")
                        .font(.nunito(13, weight: .semibold))
                        .foregroundColor(.appMuted)

                    Text(String(format: "$%.2f", expense.totalAmount))
                        .font(.nunito(44, weight: .heavy))
                        .foregroundColor(.appTerra)

                    Text(expense.title)
                        .font(.nunito(20, weight: .heavy))
                        .foregroundColor(.appText)

                    if let payer = group.members.first(where: { $0.id == expense.paidByMemberId }) {
                        HStack(spacing: 8) {
                            AvatarView(name: payer.name, size: 22)
                            Text("Paid by \(payer.name) · \(expense.date.shortFormatted)")
                                .font(.nunito(13, weight: .semibold))
                                .foregroundColor(.appMuted)
                        }
                    }

                    billStatusLine(expense: expense, payerName: payerName)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 14) {
                    Text(expense.splitType.displayLabel)
                        .font(.nunito(15, weight: .heavy))
                        .foregroundColor(.appText)

                    ForEach(orderedParticipants(expense: expense, group: group), id: \.id) { member in
                        participantRow(member: member, expense: expense, payerName: payerName, group: group)
                    }

                    paymentsSection(expense: expense, group: group)
                }

                if let note = expense.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note")
                            .font(.nunito(11, weight: .heavy))
                            .foregroundColor(.appMuted)
                            .tracking(0.6)
                        Text(note)
                            .font(.nunito(14, weight: .semibold))
                            .foregroundColor(.appText)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func billStatusLine(expense: Expense, payerName: String) -> some View {
        Group {
            if expense.unsettledAmount > Expense.balanceEpsilon {
                Text("\(CurrencyFormatter.format(expense.unsettledAmount)) unpaid toward \(payerName) on this bill")
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(.appTerra)
            } else if !expense.isFullySettled {
                Text("Participant balances still need settling on this bill")
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(.appMuted)
            } else {
                Text("Paid up on this bill")
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(.appSageDark)
            }
        }
        .padding(.top, 2)
    }

    private func participantRow(member: Member, expense: Expense, payerName: String, group: SplitGroup) -> some View {
        let isPayer = member.id == expense.paidByMemberId
        let row = expense.participantRow(for: member.id)
        let share = row?.owedAmount ?? 0
        let signed = expense.signedBalanceTowardPayer(memberId: member.id)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                AvatarView(name: member.name, size: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name)
                        .font(.nunito(15, weight: .bold))
                        .foregroundColor(.appText)

                    if isPayer {
                        Text("Paid upfront")
                            .font(.nunito(11, weight: .semibold))
                            .foregroundColor(.appTerra)
                        if expense.unsettledAmount > Expense.balanceEpsilon {
                            Text("Others still owe \(CurrencyFormatter.format(expense.unsettledAmount)) toward this bill")
                                .font(.nunito(11, weight: .semibold))
                                .foregroundColor(.appMuted)
                        } else if !expense.isFullySettled {
                            Text("Participant balances still need settling")
                                .font(.nunito(11, weight: .semibold))
                                .foregroundColor(.appMuted)
                        } else {
                            Text("Even for this bill")
                                .font(.nunito(11, weight: .semibold))
                                .foregroundColor(.appSageDark)
                        }
                    } else {
                        participantSubtitle(payerName: payerName, signed: signed)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(String(format: "$%.2f", share))
                        .font(.nunito(15, weight: .bold))
                        .foregroundColor(.appText)

                    if !isPayer {
                        if expense.maxAdditionalPaymentTowardPayer(memberId: member.id) > Expense.balanceEpsilon {
                            TerraButton(label: "Settle", outline: true, small: true) {
                                Haptics.warning()
                                settleIntent = .participantPays(participantId: member.id)
                            }
                            .accessibilityLabel("Settle for \(member.name)")
                        } else if expense.maxRepaymentFromPayer(to: member.id) > Expense.balanceEpsilon {
                            TerraButton(label: "Settle", outline: true, small: true) {
                                Haptics.warning()
                                settleIntent = .payerRepays(participantId: member.id)
                            }
                            .accessibilityLabel("Record refund from payer to \(member.name)")
                        } else if signed <= -Expense.balanceEpsilon {
                            Text("\(CurrencyFormatter.format(abs(signed))) overpaid toward \(payerName)")
                                .font(.nunito(11, weight: .semibold))
                                .foregroundColor(.appMuted)
                                .multilineTextAlignment(.trailing)
                                .accessibilityLabel("\(CurrencyFormatter.format(abs(signed))) overpaid toward payer")
                        } else {
                            Text("Settled")
                                .font(.nunito(12, weight: .heavy))
                                .foregroundColor(.appSageDark)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func participantSubtitle(payerName: String, signed: Double) -> some View {
        Group {
            if signed > Expense.balanceEpsilon {
                Text("\(CurrencyFormatter.format(signed)) still owed to \(payerName)")
                    .font(.nunito(11, weight: .semibold))
                    .foregroundColor(.appMuted)
            } else if signed < -Expense.balanceEpsilon {
                Text("\(CurrencyFormatter.format(abs(signed))) more than share toward \(payerName)")
                    .font(.nunito(11, weight: .semibold))
                    .foregroundColor(.appMuted)
            } else {
                Text("Paid up toward \(payerName)")
                    .font(.nunito(11, weight: .semibold))
                    .foregroundColor(.appSageDark)
            }
        }
    }

    @ViewBuilder
    private func paymentsSection(expense: Expense, group: SplitGroup) -> some View {
        if !expense.payments.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Payments")
                    .font(.nunito(11, weight: .heavy))
                    .foregroundColor(.appMuted)

                ForEach(expense.payments.sorted { $0.recordedAt > $1.recordedAt }) { payment in
                    let fromName = group.members.first { $0.id == payment.paidByMemberId }?.name ?? "Member"
                    let toName = group.members.first { $0.id == payment.paidToMemberId }?.name ?? "Member"
                    HStack {
                        Text("\(fromName) → \(toName)")
                            .font(.nunito(13, weight: .semibold))
                            .foregroundColor(.appText)
                        Spacer()
                        Text(CurrencyFormatter.format(payment.amount))
                            .font(.nunito(13, weight: .heavy))
                            .foregroundColor(.appTerra)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, 4)
        }
    }

    private func orderedParticipants(expense: Expense, group: SplitGroup) -> [Member] {
        let map = Dictionary(uniqueKeysWithValues: group.members.map { ($0.id, $0) })
        let payerId = expense.paidByMemberId
        let orderedIds = expense.participants.map(\.memberId)
        let others = orderedIds.filter { $0 != payerId }
        let head = orderedIds.contains(payerId) ? [payerId] : []
        return (head + others).compactMap { map[$0] }
    }

    private func settleAlertMessage(for intent: ExpenseSettleIntent) -> String {
        guard let group = group,
              let expense = expense,
              let payer = group.members.first(where: { $0.id == expense.paidByMemberId }) else {
            return ""
        }
        switch intent {
        case .participantPays(let participantId):
            guard let m = group.members.first(where: { $0.id == participantId }) else { return "" }
            let amt = expense.maxAdditionalPaymentTowardPayer(memberId: participantId)
            return "Records a payment of \(CurrencyFormatter.format(amt)) from \(m.name) to \(payer.name) on this bill."
        case .payerRepays(let participantId):
            guard let m = group.members.first(where: { $0.id == participantId }) else { return "" }
            let amt = expense.maxRepaymentFromPayer(to: participantId)
            return "\(payer.name) returns \(CurrencyFormatter.format(amt)) to \(m.name) on this bill."
        }
    }

    private func commitSettle(_ intent: ExpenseSettleIntent) {
        guard let expense = expense else { return }
        switch intent {
        case .participantPays(let participantId):
            let amt = expense.maxAdditionalPaymentTowardPayer(memberId: participantId)
            guard amt > Expense.balanceEpsilon else { return }
            viewModel.addPayment(
                groupId: groupId,
                expenseId: expenseId,
                paidByMemberId: participantId,
                paidToMemberId: expense.paidByMemberId,
                amount: amt
            )
        case .payerRepays(let participantId):
            let amt = expense.maxRepaymentFromPayer(to: participantId)
            guard amt > Expense.balanceEpsilon else { return }
            viewModel.addPayment(
                groupId: groupId,
                expenseId: expenseId,
                paidByMemberId: expense.paidByMemberId,
                paidToMemberId: participantId,
                amount: amt
            )
        }
        settleIntent = nil
    }
}

private enum ExpenseSettleIntent: Identifiable, Hashable {
    case participantPays(participantId: UUID)
    case payerRepays(participantId: UUID)

    var id: String {
        switch self {
        case .participantPays(let id): return "pay-\(id.uuidString)"
        case .payerRepays(let id): return "ref-\(id.uuidString)"
        }
    }
}
