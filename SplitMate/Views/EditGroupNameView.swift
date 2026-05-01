import SwiftUI

struct EditGroupNameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @State private var groupName: String
    @FocusState private var nameFocused: Bool

    init(viewModel: GroupViewModel, groupId: UUID, currentName: String) {
        self.viewModel = viewModel
        self.groupId = groupId
        _groupName = State(initialValue: currentName)
    }

    private var trimmed: String {
        groupName.trimmingCharacters(in: .whitespaces)
    }

    private var canSave: Bool { !trimmed.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Group Name")
                .font(.nunito(20, weight: .heavy))
                .foregroundColor(.appText)

            VStack(alignment: .leading, spacing: 6) {
                Text("GROUP NAME")
                    .font(.nunito(13, weight: .bold))
                    .foregroundColor(.appMuted)
                    .tracking(0.5)
                TextField("Group name", text: $groupName)
                    .font(.nunito(16, weight: .bold))
                    .foregroundColor(.appText)
                    .focused($nameFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.appBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appTerra, lineWidth: 1.5)
                    )
            }

            HStack(spacing: 10) {
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

                TerraButton(label: "Save", fullWidth: true) {
                    viewModel.renameGroup(id: groupId, newName: trimmed)
                    dismiss()
                }
                .opacity(canSave ? 1 : 0.5)
                .disabled(!canSave)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appWhite.ignoresSafeArea())
        .onAppear { nameFocused = true }
    }
}
