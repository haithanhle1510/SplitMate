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
                content(group: group)
            }
        }
    }

    // MARK: - Content router

    @ViewBuilder
    private func content(group: SplitGroup) -> some View {
        if group.members.isEmpty {
            EmptyStateView(
                emoji: "👥",
                title: "Add some friends first.",
                message: "Head to Settings to invite people to this group.",
                ctaLabel: "Go to Settings",
                onCtaTap: { selectedTab = 2 }
            )
        } else if group.expenses.isEmpty {
            VStack(alignment: .leading, spacing: 24) {
                memberCluster(group: group)
                    .padding(.top, 16)
                EmptyStateView(
                    emoji: "🧾",
                    title: "Nothing to split yet.",
                    message: "Add your first expense from the Expenses tab.",
                    ctaLabel: "Go to Expenses",
                    onCtaTap: { selectedTab = 1 }
                )
            }
        } else {
            overview(group: group)
        }
    }

    // MARK: - Overview

    private func overview(group: SplitGroup) -> some View {
        let totalSpent = viewModel.totalSpent(groupId: groupId)
        let pairs = viewModel.pairwiseNetDebts(groupId: groupId)

        return ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                memberCluster(group: group)
                totalSpentCard(totalSpent: totalSpent, expenseCount: group.expenses.count)
                pairsSection(pairs: pairs)
                Spacer().frame(height: 24)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Members strip

    private func memberCluster(group: SplitGroup) -> some View {
        HStack(alignment: .center, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(group.members) { member in
                        AvatarView(name: member.name, size: 36)
                            .accessibilityLabel(member.name)
                    }
                }
                .padding(.trailing, 4)
            }
            Text("\(group.members.count) \(group.members.count == 1 ? "member" : "members")")
                .font(.nunito(11, weight: .semibold))
                .tracking(0.4)
                .foregroundColor(.appMuted)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Total spent card

    private func totalSpentCard(totalSpent: Double, expenseCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total spent")
                .font(.nunito(11, weight: .heavy))
                .tracking(0.6)
                .foregroundColor(.appMuted)
            Text(CurrencyFormatter.format(totalSpent))
                .font(.nunito(50, weight: .black))
                .foregroundColor(.appText)
                .tracking(-0.8)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text("across \(expenseCount) \(expenseCount == 1 ? "expense" : "expenses")")
                .font(.nunito(13, weight: .semibold))
                .foregroundColor(.appMuted)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Pairs section ("who pays who")

    @ViewBuilder
    private func pairsSection(pairs: [Debt]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Outstanding Balance")
                .font(.nunito(11, weight: .heavy))
                .tracking(0.6)
                .foregroundColor(.appMuted)
                .padding(.horizontal, 20)

            if pairs.isEmpty {
                Text("No outstanding balance")
                    .font(.nunito(15, weight: .heavy))
                    .foregroundColor(.appText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18).stroke(Color.appBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 14)
            } else {
                pairList(pairs: pairs)
            }
        }
    }

    private func pairList(pairs: [Debt]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(pairs.enumerated()), id: \.element.id) { idx, debt in
                NavigationLink {
                    PairBreakdownView(viewModel: viewModel, groupId: groupId, debt: debt)
                } label: {
                    pairRow(debt: debt)
                }
                .buttonStyle(.plain)

                if idx < pairs.count - 1 {
                    Rectangle()
                        .fill(Color.appBorder)
                        .frame(height: 1)
                        .padding(.leading, 20)
                }
            }
        }
        .background(Color.appWhite)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18).stroke(Color.appBorder, lineWidth: 1)
        )
        .padding(.horizontal, 14)
    }

    private func pairRow(debt: Debt) -> some View {
        HStack(spacing: 10) {
            AvatarView(name: debt.debtor.name, size: 32)
            Text(debt.debtor.name)
                .font(.nunito(15, weight: .heavy))
                .foregroundColor(.appText)
            Text("pays")
                .font(.nunito(12, weight: .semibold))
                .foregroundColor(.appMuted)
            Text(debt.creditor.name)
                .font(.nunito(15, weight: .heavy))
                .foregroundColor(.appText)

            Spacer()

            Text(CurrencyFormatter.format(debt.amount))
                .font(.nunito(15, weight: .black))
                .foregroundColor(.appTerra)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.appMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(debt.debtor.name) pays \(debt.creditor.name) \(CurrencyFormatter.format(debt.amount))")
    }
}
