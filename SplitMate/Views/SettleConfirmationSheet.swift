import SwiftUI

struct SettleConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let debtorName: String
    let creditorName: String
    let amount: Double
    let expenseCount: Int
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 24) {

            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Settle up")
                    .font(.nunito(20, weight: .heavy))
                    .foregroundColor(.appText)

                HStack(spacing: 4) {
                    Text(CurrencyFormatter.format(amount))
                        .font(.nunito(15, weight: .bold))
                        .foregroundColor(.appTerra)
                    Text("from \(debtorName) to \(creditorName)")
                        .font(.nunito(15, weight: .semibold))
                        .foregroundColor(.appMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Avatars
            HStack(spacing: 16) {
                Spacer()
                VStack(spacing: 6) {
                    AvatarView(name: debtorName, size: 48)
                    Text(debtorName)
                        .font(.nunito(13, weight: .bold))
                        .foregroundColor(.appText)
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appTerra)

                VStack(spacing: 6) {
                    AvatarView(name: creditorName, size: 48)
                    Text(creditorName)
                        .font(.nunito(13, weight: .bold))
                        .foregroundColor(.appText)
                }
                Spacer()
            }

            // Expense count
            Text("Covers \(expenseCount) expense\(expenseCount == 1 ? "" : "s") across this group")
                .font(.nunito(13, weight: .semibold))
                .foregroundColor(.appMuted)

            // Buttons
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.nunito(16, weight: .heavy))
                        .foregroundColor(.appMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appBorder, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text("Settle \(CurrencyFormatter.format(amount))")
                        .font(.nunito(16, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.appTerra)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(Color.appWhite)
        .cornerRadius(20)
        .overlay(
            Capsule()
                .fill(Color.appWarmGray)
                .frame(width: 36, height: 4)
                .padding(.top, 10),
            alignment: .top
        )
    }
}

#Preview {
    SettleConfirmationSheet(
        debtorName: "Mia",
        creditorName: "Alex",
        amount: 15.00,
        expenseCount: 3,
        onConfirm: {}
    )
}
