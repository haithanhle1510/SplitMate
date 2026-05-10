import SwiftUI

struct PairBreakdownView: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    let debt: Debt
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettleConfirm = false

    private var contributions: [PairContribution] {
        viewModel.pairContributions(groupId: groupId, debtor: debt.debtor, creditor: debt.creditor)
    }

    /// Re-derive the live net (in case data changed) — falls back to the snapshot if pair vanished.
    private var liveAmount: Double {
        let net = contributions.reduce(0) { $0 + $1.amount }
        return abs(net) > 0.01 ? net : debt.amount
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    header
                    contributionsCard
                    Spacer().frame(height: 12)
                    if abs(liveAmount) > 0.02 {
                        settleButton
                    }
                    Spacer().frame(height: 24)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Breakdown")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert(
            "Settle all",
            isPresented: $showingSettleConfirm
        ) {
            Button("Cancel", role: .cancel) { }
            Button("Settle all") {
                viewModel.settleBetweenPair(
                    groupId: groupId,
                    memberA: debt.debtor.id,
                    memberB: debt.creditor.id
                )
                Haptics.selection()
                dismiss()
            }
        } message: {
            Text("Settles all outstanding balance for \(debt.debtor.name) to \(debt.creditor.name).")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                AvatarView(name: debt.debtor.name, size: 48)
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.appMuted)
                AvatarView(name: debt.creditor.name, size: 48)
            }
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(debt.debtor.name)
                        .font(.nunito(16, weight: .heavy))
                        .foregroundColor(.appText)
                    Text("pays")
                        .font(.nunito(13, weight: .semibold))
                        .foregroundColor(.appMuted)
                    Text(debt.creditor.name)
                        .font(.nunito(16, weight: .heavy))
                        .foregroundColor(.appText)
                }
                Text(CurrencyFormatter.format(abs(liveAmount)))
                    .font(.nunito(40, weight: .black))
                    .foregroundColor(.appTerra)
                    .tracking(-0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Contributions card

    private var contributionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How we got there")
                .font(.nunito(11, weight: .heavy))
                .tracking(0.6)
                .foregroundColor(.appMuted)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(contributions.enumerated()), id: \.element.id) { idx, c in
                    contributionRow(c)
                    if idx < contributions.count - 1 {
                        Rectangle()
                            .fill(Color.appBorder)
                            .frame(height: 1)
                            .padding(.leading, 20)
                    }
                }
                Rectangle()
                    .fill(Color.appBorder)
                    .frame(height: 1)
                netRow
            }
            .background(Color.appWhite)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18).stroke(Color.appBorder, lineWidth: 1)
            )
            .padding(.horizontal, 14)
        }
    }

    private func contributionRow(_ c: PairContribution) -> some View {
        // Sign is from the debtor's wallet perspective:
        //   c.amount > 0 → debtor owes more for this expense → wallet loses → "−"
        //   c.amount < 0 → creditor owes debtor for this expense → wallet gains → "+"
        let walletGain = c.amount < 0
        let sign = walletGain ? "+" : "−"
        let signColor: Color = walletGain ? .appSageDark : .appTerra
        let payerName = (c.amount > 0) ? debt.creditor.name : debt.debtor.name

        return HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(c.expense.date.dayString)
                    .font(.nunito(16, weight: .black))
                    .foregroundColor(.appText)
                Text(c.expense.date.monthShortString.uppercased())
                    .font(.nunito(9, weight: .heavy))
                    .tracking(0.6)
                    .foregroundColor(.appMuted)
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(c.expense.title)
                    .font(.nunito(14, weight: .heavy))
                    .foregroundColor(.appText)
                Text("\(payerName) paid \(CurrencyFormatter.format(c.expense.totalAmount)) · \(c.expense.splitType.displayLabel.lowercased())")
                    .font(.nunito(11, weight: .semibold))
                    .foregroundColor(.appMuted)
            }

            Spacer()

            HStack(spacing: 2) {
                Text(sign)
                    .font(.nunito(14, weight: .black))
                    .foregroundColor(signColor)
                Text(CurrencyFormatter.format(abs(c.amount)))
                    .font(.nunito(14, weight: .heavy))
                    .foregroundColor(.appText)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var netRow: some View {
        HStack {
            Text("Net")
                .font(.nunito(12, weight: .heavy))
                .tracking(0.4)
                .foregroundColor(.appMuted)
            Spacer()
            Text(CurrencyFormatter.format(abs(liveAmount)))
                .font(.nunito(16, weight: .black))
                .foregroundColor(.appTerra)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.appBg.opacity(0.55))
    }

    // MARK: - Settle

    private var settleButton: some View {
        Button {
            Haptics.warning()
            showingSettleConfirm = true
        } label: {
            Text("Settle all")
                .font(.nunito(15, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appSageDark)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .accessibilityLabel("Settle all with \(debt.creditor.name)")
    }
}
