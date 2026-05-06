import SwiftUI

struct MemberBalance: Identifiable {
    let id = UUID()
    let name: String
    let totalBalance: Double
    let details: [String]
}

struct MemberView: View {

    let members: [MemberBalance] = [
        MemberBalance(
            name: "Alex",
            totalBalance: 40.00,
            details: [
                "Mia owes Alex $20.00",
                "John owes Alex $20.00"
            ]
        ),
        MemberBalance(
            name: "Mia",
            totalBalance: -20.00,
            details: [
                "Mia owes Alex $20.00"
            ]
        ),
        MemberBalance(
            name: "John",
            totalBalance: -20.00,
            details: [
                "John owes Alex $20.00"
            ]
        ),
        MemberBalance(
            name: "Mary",
            totalBalance: 0.00,
            details: [
                "No outstanding balance"
            ]
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        Text("Members")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.appText)
                            .padding(.horizontal)
                            .padding(.top)

                        Text("View each member's total balance and detailed debt information.")
                            .font(.subheadline)
                            .foregroundStyle(Color.appMuted)
                            .padding(.horizontal)

                        ForEach(members) { member in
                            memberCard(member)
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
    }
    

    private func memberCard(_ member: MemberBalance) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(member.details, id: \.self) { detail in
                    HStack(alignment: .center, spacing: 8) {
                        Circle()
                            .fill(Color.appPeach)
                            .frame(width: 6, height: 6)

                        Text(detail)
                            .font(.subheadline)
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
                        .font(.headline)
                        .foregroundStyle(Color.appText)

                    Text(statusText(for: member.totalBalance))
                        .font(.caption)
                        .foregroundStyle(Color.appMuted)
                }

                Spacer()

                Text(balanceText(for: member.totalBalance))
                    .font(.headline)
                    .fontWeight(.semibold)
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



    private func balanceText(for balance: Double) -> String {
        if balance > 0 {
            return "+$\(String(format: "%.2f", balance))"
        } else if balance < 0 {
            return "-$\(String(format: "%.2f", abs(balance)))"
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
    MemberView()
}
