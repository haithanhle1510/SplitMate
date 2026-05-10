import SwiftUI

struct ExpenseFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filter: ExpenseFilter
    let members: [Member]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        membersSection
                        statusSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Filter")
                        .font(.nunito(17, weight: .heavy))
                        .foregroundColor(.appText)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { filter = .empty }
                        .font(.nunito(15, weight: .semibold))
                        .foregroundColor(filter.isActive ? .appTerra : .appMuted)
                        .disabled(!filter.isActive)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.nunito(15, weight: .heavy))
                        .foregroundColor(.appTerra)
                }
            }
            .toolbarBackground(Color.appBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Sections

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MEMBERS")
                .font(.nunito(11, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(.appMuted)

            FlowLayout(spacing: 8) {
                ForEach(members) { member in
                    chip(for: member)
                }
            }

            if filter.memberIds.count > 1 {
                Text("Only expenses that include every selected member.")
                    .font(.nunito(11, weight: .semibold))
                    .foregroundColor(.appMuted)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STATUS")
                .font(.nunito(11, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(.appMuted)

            Button {
                filter.unsettledOnly.toggle()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(filter.unsettledOnly ? Color.appTerra : Color.appWhite)
                            .frame(width: 22, height: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(filter.unsettledOnly ? Color.appTerra : Color.appBorder, lineWidth: 1.5)
                            )
                        if filter.unsettledOnly {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    Text("Unsettled only")
                        .font(.nunito(15, weight: .bold))
                        .foregroundColor(.appText)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.appWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(for member: Member) -> some View {
        let isOn = filter.memberIds.contains(member.id)
        return Button {
            if isOn { filter.memberIds.remove(member.id) }
            else { filter.memberIds.insert(member.id) }
        } label: {
            HStack(spacing: 8) {
                AvatarView(name: member.name, size: 24)
                Text(member.name)
                    .font(.nunito(13, weight: .heavy))
                    .foregroundColor(isOn ? .white : .appText)
            }
            .padding(.leading, 4)
            .padding(.trailing, 12)
            .padding(.vertical, 4)
            .background(isOn ? Color.appTerra : Color.appWhite)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isOn ? Color.appTerra : Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// Simple flow layout for chips that wrap
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let size = subviews[item].sizeThatFits(.unspecified)
                subviews[item].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var items: [Int]; var height: CGFloat }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row(items: [], height: 0)]
        var x: CGFloat = 0
        for (i, sub) in subviews.enumerated() {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > maxWidth, !rows[rows.count - 1].items.isEmpty {
                rows.append(Row(items: [], height: 0))
                x = 0
            }
            rows[rows.count - 1].items.append(i)
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, s.height)
            x += s.width + spacing
        }
        return rows
    }
}
