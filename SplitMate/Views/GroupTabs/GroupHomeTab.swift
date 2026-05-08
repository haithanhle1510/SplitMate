import SwiftUI

struct GroupHomeTab: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @Binding var selectedTab: Int

    private var group: SplitGroup? {
        viewModel.groups.first { $0.id == groupId }
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            if let group {
                if group.members.isEmpty {
                    EmptyStateView(
                        emoji: "👥",
                        title: "Add some friends first.",
                        message: "Head to Settings to invite people to this group.",
                        ctaLabel: "Go to Settings",
                        onCtaTap: { selectedTab = 2 }
                    )
                } else if group.expenses.isEmpty {
                    VStack(spacing: 0) {
                        memberAvatarsRow(group: group)
                        EmptyStateView(
                            emoji: "🧾",
                            title: "Nothing to split yet.",
                            message: "Add your first expense from the Expenses tab.",
                            ctaLabel: "Go to Expenses",
                            onCtaTap: { selectedTab = 1 }
                        )
                    }
                } else {
                    VStack(spacing: 0) {
                        memberAvatarsRow(group: group)
                        summaryPlaceholder
                    }
                }
            }
        }
    }

    private func memberAvatarsRow(group: SplitGroup) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(group.members) { member in
                    VStack(spacing: 4) {
                        AvatarView(name: member.name, size: 40)
                        Text(member.name)
                            .font(.nunito(11, weight: .bold))
                            .foregroundColor(.appMuted)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.appBg)
        .overlay(Rectangle().fill(Color.appBorder).frame(height: 1), alignment: .bottom)
    }

    private var summaryPlaceholder: some View {
        let directDebts = group.map { viewModel.groupDirectDebts(groupId: $0.id) } ?? []
        let simplifiedDebts = group.map { viewModel.groupSimplifiedDebts(groupId: $0.id) } ?? []
        
        return ScrollView {
            VStack(spacing: 16) {
                whoOwesWhoSection(directDebts: directDebts, group: group!)
                if !simplifiedDebts.isEmpty && directDebts.count > simplifiedDebts.count {
                    simplificationTipsSection(directDebts: directDebts, simplifiedDebts: simplifiedDebts)
                }
                Spacer().frame(height: 8)
            }
            .padding(.vertical, 12)
        }
    }

    private func whoOwesWhoSection(directDebts: [Debt], group: SplitGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Who owes who")
                    .font(.nunito(15, weight: .heavy))
                    .foregroundColor(.appText)
                Spacer()
                Text("\(directDebts.count) transactions")
                    .font(.nunito(11, weight: .semibold))
                    .foregroundColor(.appMuted)
            }

            if directDebts.isEmpty {
                VStack(spacing: 8) {
                    Text("All settled!")
                        .font(.nunito(13, weight: .semibold))
                        .foregroundColor(.appTerra)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.appSageLt)
                .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(directDebts.enumerated()), id: \.element.id) { idx, debt in
                        DisclosureGroup {
                            if !debt.expenseIds.isEmpty {
                                let expenses = viewModel.getExpensesForDebt(debt, groupId: group.id)
                                VStack(spacing: 0) {
                                    ForEach(expenses) { expense in
                                        ExpenseMiniRow(expense: expense)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(debt.debtor.name) owes \(debt.creditor.name)")
                                    .font(.nunito(14, weight: .bold))
                                    .foregroundColor(.appText)
                                Spacer()
                                Text(String(format: "$%.2f", debt.amount))
                                    .font(.nunito(14, weight: .bold))
                                    .foregroundColor(.appText)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                        if idx < directDebts.count - 1 {
                            Divider()
                                .background(Color.appBorder)
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .background(Color.appWhite)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1)
                )
            }
        }
        .padding(14)
        .background(Color.appWhite)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1)
        )
        .padding(.horizontal, 14)
    }

    private func simplificationTipsSection(directDebts: [Debt], simplifiedDebts: [Debt]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💡 Simplification Tips")
                    .font(.nunito(15, weight: .heavy))
                    .foregroundColor(.appText)
                Spacer()
                Text("\(simplifiedDebts.count) payments")
                    .font(.nunito(11, weight: .semibold))
                    .foregroundColor(.appSage)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Instead of \(directDebts.count) transactions, simplify to:")
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(.appMuted)

                VStack(spacing: 0) {
                    ForEach(Array(simplifiedDebts.enumerated()), id: \.element.id) { idx, debt in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(debt.debtor.name) pays \(debt.creditor.name)")
                                    .font(.nunito(13, weight: .bold))
                                    .foregroundColor(.appText)
                            }
                            Spacer()
                            Text(String(format: "$%.2f", debt.amount))
                                .font(.nunito(13, weight: .bold))
                                .foregroundColor(.appSage)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                        if idx < simplifiedDebts.count - 1 {
                            Divider()
                                .background(Color.appBorder)
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .background(Color.appSageLt)
                .cornerRadius(8)

                let savings = directDebts.count - simplifiedDebts.count
                let percentage = Int((Double(savings) / Double(directDebts.count)) * 100)

                Text("💰 Save \(savings) transaction\(savings > 1 ? "s" : "") (\(percentage)% fewer)")
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(.appSage)
            }
        }
        .padding(14)
        .background(Color.appWhite)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1)
        )
        .padding(.horizontal, 14)
    }
}
