import SwiftUI

struct MemberRow: View {
    let member: Member
    var balance: Double = 0
    var onSettleAll: (() -> Void)? = nil

    private var subLabel: String {
        if balance > 0 {
            return "is owed \(CurrencyFormatter.format(balance))"
        } else if balance < 0 {
            return "owes \(CurrencyFormatter.format(balance))"
        } else {
            return "settled"
        }
    }

    private var isSettled: Bool { balance == 0 }

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(name: member.name, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.nunito(15, weight: .heavy))
                    .foregroundColor(.appText)
                Text(subLabel)
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(isSettled ? .appMuted : .appText)
            }
            Spacer()
            if !isSettled, let onSettleAll {
                TerraButton(label: "Settle all", outline: true, small: true, action: onSettleAll)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
