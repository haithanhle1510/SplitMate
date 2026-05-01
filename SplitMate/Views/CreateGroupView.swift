import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel
    @State private var groupName: String = ""
    @FocusState private var nameFocused: Bool

    private var trimmed: String {
        groupName.trimmingCharacters(in: .whitespaces)
    }

    private var canCreate: Bool { !trimmed.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Group")
                .font(.nunito(20, weight: .heavy))
                .foregroundColor(.appText)

            VStack(alignment: .leading, spacing: 6) {
                Text("GROUP NAME")
                    .font(.nunito(13, weight: .bold))
                    .foregroundColor(.appMuted)
                    .tracking(0.5)
                TextField("e.g. Bali Trip", text: $groupName)
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

                TerraButton(label: "Create", fullWidth: true) {
                    viewModel.addGroup(name: trimmed)
                    dismiss()
                }
                .opacity(canCreate ? 1 : 0.5)
                .disabled(!canCreate)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appWhite.ignoresSafeArea())
        .onAppear { nameFocused = true }
    }
}

#Preview {
    CreateGroupView(viewModel: GroupViewModel())
}
