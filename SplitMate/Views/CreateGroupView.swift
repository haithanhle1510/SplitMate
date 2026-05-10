import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel
    var onCreated: (UUID) -> Void = { _ in }

    @State private var groupName: String = ""
    @State private var memberInput: String = ""
    @State private var pendingMembers: [String] = []
    @FocusState private var nameFocused: Bool
    @FocusState private var memberFocused: Bool

    private var trimmedName: String { groupName.trimmingCharacters(in: .whitespaces) }
    private var trimmedMember: String { memberInput.trimmingCharacters(in: .whitespaces) }
    private var canCreate: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        nameSection
                        membersSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Group")
                        .font(.nunito(17, weight: .heavy))
                        .foregroundColor(.appText)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.nunito(15, weight: .semibold))
                        .foregroundColor(.appMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { commitCreate() }
                        .font(.nunito(15, weight: .heavy))
                        .foregroundColor(canCreate ? .appTerra : .appMuted)
                        .disabled(!canCreate)
                }
            }
            .toolbarBackground(Color.appBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear { nameFocused = true }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GROUP NAME")
                .font(.nunito(12, weight: .bold))
                .tracking(0.6)
                .foregroundColor(.appMuted)

            TextField("e.g. Bali Trip", text: $groupName)
                .font(.nunito(16, weight: .bold))
                .foregroundColor(.appText)
                .focused($nameFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color.appWhite)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(nameFocused ? Color.appTerra : Color.appBorder, lineWidth: 1.5)
                )
                .submitLabel(.next)
                .onSubmit { memberFocused = true }
        }
    }

    // MARK: - Members Section

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MEMBERS")
                .font(.nunito(12, weight: .bold))
                .tracking(0.6)
                .foregroundColor(.appMuted)

            VStack(spacing: 0) {
                ForEach(Array(pendingMembers.enumerated()), id: \.offset) { idx, name in
                    HStack(spacing: 12) {
                        AvatarView(name: name, size: 34)
                        Text(name)
                            .font(.nunito(15, weight: .bold))
                            .foregroundColor(.appText)
                        Spacer()
                        Button {
                            pendingMembers.remove(at: idx)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.appMuted)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(name)")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)

                    Rectangle().fill(Color.appBorder).frame(height: 1)
                }

                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4]))
                            .foregroundColor(.appBorder)
                            .frame(width: 34, height: 34)
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.appMuted)
                    }

                    TextField("Add member name", text: $memberInput)
                        .font(.nunito(15, weight: .bold))
                        .foregroundColor(.appText)
                        .focused($memberFocused)
                        .submitLabel(.done)
                        .onSubmit { addPendingMember() }

                    if !trimmedMember.isEmpty {
                        Button("Add") { addPendingMember() }
                            .font(.nunito(13, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.appTerra)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
            .background(Color.appWhite)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func addPendingMember() {
        guard !trimmedMember.isEmpty else { return }
        pendingMembers.append(trimmedMember)
        memberInput = ""
        memberFocused = true
    }

    private func commitCreate() {
        guard canCreate else { return }
        let id = viewModel.addGroup(name: trimmedName)
        for name in pendingMembers {
            viewModel.addMember(toGroupId: id, name: name)
        }
        dismiss()
        onCreated(id)
    }
}

#Preview {
    CreateGroupView(viewModel: GroupViewModel())
}
