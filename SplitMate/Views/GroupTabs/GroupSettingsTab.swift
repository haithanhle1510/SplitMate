import SwiftUI

struct GroupSettingsTab: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    var onGroupDeleted: () -> Void = {}

    @State private var showingAddMember = false
    @State private var showingEditName = false
    @State private var showingDeleteConfirm = false
    @State private var showingRemoveBlocked = false
    @State private var memberToRemove: Member? = nil

    private var group: SplitGroup? {
        viewModel.groups.first { $0.id == groupId }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            if let group {
                ScrollView {
                    VStack(spacing: 14) {
                        groupSection(group: group)
                        membersSection(group: group)
                        deleteSection
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }
            }
        }
        .sheet(isPresented: $showingAddMember) {
            AddMemberView(viewModel: viewModel, groupId: groupId)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEditName) {
            if let group {
                EditGroupNameView(viewModel: viewModel, groupId: groupId, currentName: group.name)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Delete group?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteGroup(id: groupId)
                onGroupDeleted()
            }
        } message: {
            Text("This cannot be undone.")
        }
        .alert("Cannot remove member", isPresented: $showingRemoveBlocked) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This member has expenses in the group. Remove or settle their expenses first.")
        }
        .alert(
            "Remove member?",
            isPresented: Binding(
                get: { memberToRemove != nil },
                set: { if !$0 { memberToRemove = nil } }
            ),
            presenting: memberToRemove
        ) { member in
            Button("Cancel", role: .cancel) { memberToRemove = nil }
            Button("Remove", role: .destructive) {
                attemptRemove(memberId: member.id)
                memberToRemove = nil
            }
        } message: { member in
            Text("Remove \(member.name) from this group?")
        }
    }

    private func groupSection(group: SplitGroup) -> some View {
        sectionCard {
            sectionHeader("Group")
            Button {
                showingEditName = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.name)
                            .font(.nunito(18, weight: .heavy))
                            .foregroundColor(.appText)
                        Text("Created on \(Self.dateFormatter.string(from: group.createdAt))")
                            .font(.nunito(13, weight: .semibold))
                            .foregroundColor(.appMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }

    private func membersSection(group: SplitGroup) -> some View {
        let balances = viewModel.memberBalances(groupId: groupId)
        
        return sectionCard {
            sectionHeader("Members")
            VStack(spacing: 0) {
                ForEach(Array(balances.enumerated()), id: \.element.id) { idx, balance in
                    HStack(spacing: 12) {
                        AvatarView(name: balance.member.name, size: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(balance.member.name)
                                .font(.nunito(15, weight: .bold))
                                .foregroundColor(.appText)
                            
                            // Balance status
                            if balance.balance > 0.01 {
                                Text(balance.member.name + " is owed " + String(format: "$%.2f", balance.balance))
                                    .font(.nunito(12, weight: .semibold))
                                    .foregroundColor(.appSage)
                            } else if balance.balance < -0.01 {
                                Text(balance.member.name + " owes " + String(format: "$%.2f", abs(balance.balance)))
                                    .font(.nunito(12, weight: .semibold))
                                    .foregroundColor(.appMuted)
                            } else {
                                Text("Settled")
                                    .font(.nunito(12, weight: .semibold))
                                    .foregroundColor(.appTerra)
                            }
                        }
                        
                        Spacer()
                        
                        // Remove button (only show for members with no references in expenses)
                        if !group.expenses.contains(where: { $0.paidBy == balance.member.id || $0.participantIds.contains(balance.member.id) }) {
                            Button {
                                Haptics.warning()
                                memberToRemove = balance.member
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.appMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    
                    if idx < balances.count - 1 {
                        divider
                    }
                }
                if !group.members.isEmpty { divider }
                addMemberRow
            }
        }
    }

    private var addMemberRow: some View {
        Button {
            showingAddMember = true
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4]))
                        .foregroundColor(.appBorder)
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appMuted)
                }
                Text("Add member")
                    .font(.nunito(15, weight: .bold))
                    .foregroundColor(.appTerra)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }

    private var deleteSection: some View {
        sectionCard {
            Button {
                Haptics.warning()
                showingDeleteConfirm = true
            } label: {
                Text("Delete group")
                    .font(.nunito(15, weight: .bold))
                    .foregroundColor(.appWarmGray)
                    .frame(maxWidth: .infinity)
                    .padding(14)
            }
            .buttonStyle(.plain)
        }
    }

    private func attemptRemove(memberId: UUID) {
        let result = viewModel.removeMember(fromGroupId: groupId, memberId: memberId)
        if result == .blockedByExpenses {
            Haptics.error()
            showingRemoveBlocked = true
        }
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(Color.appWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1)
            )
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.nunito(12, weight: .bold))
            .tracking(0.6)
            .foregroundColor(.appMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(divider, alignment: .bottom)
    }

    private var divider: some View {
        Rectangle().fill(Color.appBorder).frame(height: 1)
    }
}
