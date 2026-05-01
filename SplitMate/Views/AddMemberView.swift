import SwiftUI

struct AddMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @State private var memberName: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Member Name")) {
                    TextField("e.g. Alex", text: $memberName)
                }
            }
            .navigationTitle("Add Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = memberName.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            viewModel.addMember(toGroupId: groupId, name: trimmed)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
