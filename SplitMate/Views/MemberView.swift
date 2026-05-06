import SwiftUI

struct MemberBalance: Identifiable {
    let id: UUID
    let name: String
    let totalBalance: Double
    let details: [String]
}

struct MemberView: View {

    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @State private var showAddMember = false

    private var group: SplitGroup? {
        viewModel.groups.first { $0.id == groupId }
    }

    private var memberBalances: [MemberBalance] {
        guard let group else { return [] }

        return group.members.map { member in
            var net = 0.0
            var details: [String] = []

            for expense in group.expenses {
                let share = expense.perPersonShare

                // This member paid — credit them for each unsettled participant
                if expense.paidBy == member.id {
                    for participantId in expense.participantIds {
                        guard participantId != member.id,
                              !expense.settledMemberIds.contains(participantId) else { continue }
                        net += share
                        if let debtor = group.members.first(where: { $0.id == participantId }) {
                            details.append("\(debtor.name) owes \(member.name) \(CurrencyFormatter.format(share))")
                        }
                    }
                }

                // This member is an unsettled participant — debit them
                if expense.participantIds.contains(member.id),
                   expense.paidBy != member.id,
                   !expense.settledMemberIds.contains(member.id) {
                    net -= share
                    if let payer = group.members.first(where: { $0.id == expense.paidBy }) {
                        details.append("\(member.name) owes \(payer.name) \(CurrencyFormatter.format(share))")
                    }
                }
            }

            return MemberBalance(
                id: member.id,
                name: member.name,
                totalBalance: net,
                details: details.isEmpty ? ["No outstanding balance"] : details
            )
        }
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("View each member's total balance and detailed debt information.")
                        .font(.nunito(14, weight: .semibold))
                        .foregroundStyle(Color.appMuted)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    ForEach(memberBalances) { member in
                        memberCard(member)
                    }
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddMember = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9).fill(Color.appTerra)
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .frame(width: 30, height: 30)
                }
                .accessibilityLabel("Add member")
            }
        }
        .sheet(isPresented: $showAddMember) {
            AddMemberView(viewModel: viewModel, groupId: groupId)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Card

    private func memberCard(_ member: MemberBalance) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(member.details, id: \.self) { detail in
                    HStack(alignment: .center, spacing: 8) {
                        Circle()
                            .fill(Color.appPeach)
                            .frame(width: 6, height: 6)
                        Text(detail)
                            .font(.nunito(14, weight: .semibold))
                            .foregroundStyle(Color.appMuted)
                    }
                }
            }
            .padding(.top, 10)
        } label: {
            HStack(spacing: 14) {
                AvatarView(name: member.name, size: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name)
                        .font(.nunito(15, weight: .heavy))
                        .foregroundStyle(Color.appText)

                    Text(statusText(for: member.totalBalance))
                        .font(.nunito(12, weight: .semibold))
                        .foregroundStyle(Color.appMuted)
                }

                Spacer()

                Text(balanceText(for: member.totalBalance))
                    .font(.nunito(15, weight: .heavy))
                    .foregroundStyle(balanceColor(for: member.totalBalance))
            }
        }
        .tint(Color.appTerra)
        .padding()
        .background(Color.appWhite)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func balanceText(for balance: Double) -> String {
        if balance > 0 {
            return "+\(CurrencyFormatter.format(balance))"
        } else if balance < 0 {
            return "-\(CurrencyFormatter.format(abs(balance)))"
        } else {
            return "$0.00"
        }
    }

    private func statusText(for balance: Double) -> String {
        if balance > 0 { return "Should receive" }
        else if balance < 0 { return "Owes money" }
        else { return "Settled" }
    }

    private func balanceColor(for balance: Double) -> Color {
        if balance > 0 { return .appSageDark }
        else if balance < 0 { return .appTerra }
        else { return .appMuted }
    }
}

#Preview {
    NavigationStack {
        MemberView(viewModel: GroupViewModel(), groupId: UUID())
    }
}
