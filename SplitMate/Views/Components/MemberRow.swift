import SwiftUI

struct MemberRow: View {
    let member: Member
    var balance: Double? = nil
    var onSettleAll: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil

    private var subLabel: String? {
        guard let balance else { return nil }
        if balance > 0 {
            return "is owed \(CurrencyFormatter.format(balance))"
        } else if balance < 0 {
            return "owes \(CurrencyFormatter.format(balance))"
        } else {
            return "settled"
        }
    }

    private var isSettled: Bool {
        guard let balance else { return true }
        return balance == 0
    }

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(name: member.name, size: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.nunito(15, weight: .heavy))
                    .foregroundColor(.appText)
                if let subLabel {
                    Text(subLabel)
                        .font(.nunito(12, weight: .semibold))
                        .foregroundColor(isSettled ? .appMuted : .appText)
                }
            }
            Spacer()
            if !isSettled, let onSettleAll {
                TerraButton(label: "Settle all", outline: true, small: true, action: onSettleAll)
            }
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.appWarmGray)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(member.name)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
