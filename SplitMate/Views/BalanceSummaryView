import SwiftUI

struct DebtRelationship: Identifiable {
    var id: String { "\(debtorId)-\(creditorId)" }
    let debtorId: UUID
    let creditorId: UUID
    let debtorName: String
    let creditorName: String
    var totalAmount: Double
    var expenseDetails: [ExpenseDebtDetail]
}

struct ExpenseDebtDetail: Identifiable {
    var id: UUID { expenseId }
    let expenseId: UUID
    let title: String
    let amount: Double
    let date: Date
}

struct BalanceSummaryView: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @State private var expandedKeys: Set<String> = []
    @State private var settleTarget: DebtRelationship? = nil

    private var group: SplitGroup? {
        viewModel.groups.first { $0.id == groupId }
    }

    // Replace this with BalanceCalculator when ready
    private var debtRelationships: [DebtRelationship] {
        guard let group else { return [] }

        var map: [String: DebtRelationship] = [:]

        for expense in group.expenses {
            let share = expense.perPersonShare
            guard let creditor = group.members.first(where: { $0.id == expense.paidBy }) else { continue }

            for participantId in expense.participantIds {
                guard participantId != expense.paidBy,
                      !expense.settledMemberIds.contains(participantId),
                      let debtor = group.members.first(where: { $0.id == participantId }) else { continue }

                let key = "\(participantId)-\(expense.paidBy)"
                let detail = ExpenseDebtDetail(
                    expenseId: expense.id,
                    title: expense.title,
                    amount: share,
                    date: expense.date
                )

                if var rel = map[key] {
                    rel.totalAmount += share
                    rel.expenseDetails.append(detail)
                    map[key] = rel
                } else {
                    map[key] = DebtRelationship(
                        debtorId: participantId,
                        creditorId: expense.paidBy,
                        debtorName: debtor.name,
                        creditorName: creditor.name,
                        totalAmount: share,
                        expenseDetails: [detail]
                    )
                }
            }
        }

        return Array(map.values).sorted {
            let a = ($0.totalAmount * 100).rounded()
            let b = ($1.totalAmount * 100).rounded()
            if a != b { return a > b }
            if $0.debtorName != $1.debtorName { return $0.debtorName < $1.debtorName }
            return $0.creditorName < $1.creditorName
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if debtRelationships.isEmpty {
                    VStack(spacing: 8) {
                        Text("🎉")
                            .font(.system(size: 40))
                        Text("All settled up!")
                            .font(.nunito(18, weight: .heavy))
                            .foregroundColor(.appText)
                        Text("No outstanding balances.")
                            .font(.nunito(13, weight: .semibold))
                            .foregroundColor(.appMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                } else {
                    Text("Who owes who")
                        .font(.nunito(15, weight: .heavy))
                        .foregroundColor(.appText)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    ForEach(debtRelationships) { rel in
                        debtCard(rel)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .sheet(item: $settleTarget) { rel in
            SettleConfirmationSheet(
                debtorName: rel.debtorName,
                creditorName: rel.creditorName,
                amount: rel.totalAmount,
                expenseCount: rel.expenseDetails.count,
                onConfirm: {
                    viewModel.settleBetween(groupId: groupId, debtorId: rel.debtorId, creditorId: rel.creditorId)
                    expandedKeys.remove(rel.id)
                    Haptics.selection()
                }
            )
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Debt Card

    private func debtCard(_ rel: DebtRelationship) -> some View {
        let isExpanded = expandedKeys.contains(rel.id)

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedKeys.remove(rel.id)
                    } else {
                        expandedKeys.insert(rel.id)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    AvatarView(name: rel.debtorName, size: 28)

                    Text("\(rel.debtorName) owes \(rel.creditorName)")
                        .font(.nunito(14, weight: .bold))
                        .foregroundColor(.appText)

                    Spacer()

                    Text(CurrencyFormatter.format(rel.totalAmount))
                        .font(.nunito(14, weight: .heavy))
                        .foregroundColor(.appTerra)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.appMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(isExpanded ? Color.appPeach.opacity(0.3) : Color.appWhite)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().background(Color.appBorder)

                ForEach(rel.expenseDetails) { detail in
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.appTerra)
                                .frame(width: 6, height: 6)

                            Text(detail.title)
                                .font(.nunito(13, weight: .semibold))
                                .foregroundColor(.appText)

                            Spacer()

                            Text(detail.date.shortFormatted)
                                .font(.nunito(11, weight: .semibold))
                                .foregroundColor(.appMuted)

                            Text(CurrencyFormatter.format(detail.amount))
                                .font(.nunito(13, weight: .bold))
                                .foregroundColor(.appText)
                                .frame(width: 50, alignment: .trailing)

                            Button {
                                viewModel.toggleSettlement(
                                    groupId: groupId,
                                    expenseId: detail.expenseId,
                                    memberId: rel.debtorId
                                )
                                Haptics.selection()
                            } label: {
                                Text("Settle")
                                    .font(.nunito(11, weight: .heavy))
                                    .foregroundColor(.appSageDark)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.appSageLt)
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                        if detail.id != rel.expenseDetails.last?.id {
                            Divider().background(Color.appBorder).padding(.leading, 30)
                        }
                    }
                }

                Divider().background(Color.appBorder)

                Button {
                    settleTarget = rel
                } label: {
                    Text("Settle up")
                        .font(.nunito(15, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.appTerra)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(14)
            }
        }
        .background(Color.appWhite)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
        .padding(.horizontal, 14)
    }
}

private extension Date {
    var shortFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: self)
    }
}
