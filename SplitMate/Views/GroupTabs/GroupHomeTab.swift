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
        VStack(spacing: 12) {
            Spacer().frame(height: 12)
            VStack(spacing: 8) {
                Text("Balance summary")
                    .font(.nunito(15, weight: .heavy))
                    .foregroundColor(.appText)
                Text("Coming soon")
                    .font(.nunito(13, weight: .semibold))
                    .foregroundColor(.appMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(Color.appWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1)
            )
            .padding(.horizontal, 14)
            Spacer()
        }
    }
}
