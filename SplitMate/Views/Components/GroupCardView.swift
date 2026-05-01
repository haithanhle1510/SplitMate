import SwiftUI

struct GroupCardView: View {
    let group: SplitGroup
    var unsettledAmount: Double = 0

    private var groupInitial: String {
        String(group.name.prefix(1)).uppercased()
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.appPeach)
                Text(groupInitial)
                    .font(.nunito(20, weight: .heavy))
                    .foregroundColor(.appText)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.nunito(16, weight: .heavy))
                    .foregroundColor(.appText)
                Text("\(group.members.count) member\(group.members.count == 1 ? "" : "s")")
                    .font(.nunito(13, weight: .semibold))
                    .foregroundColor(.appMuted)
            }

            Spacer()

            HStack(spacing: 6) {
                if unsettledAmount > 0 {
                    Text("\(CurrencyFormatter.format(unsettledAmount)) unsettled")
                        .font(.nunito(14, weight: .heavy))
                        .foregroundColor(.appTerra)
                } else {
                    HStack(spacing: 4) {
                        ZStack {
                            Circle().fill(Color.appSageLt).frame(width: 13, height: 13)
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.appSageDark)
                        }
                        Text("All settled")
                            .font(.nunito(14, weight: .heavy))
                            .foregroundColor(.appSageDark)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Color.appWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1)
        )
    }
}
