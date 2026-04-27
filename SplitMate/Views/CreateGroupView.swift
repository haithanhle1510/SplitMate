import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel
    @State private var groupName: String = ""
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Name")) {
                    TextField("e.g. UTS Housemates", text: $groupName)
                }
            }
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !groupName.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.addGroup(name: groupName.trimmingCharacters(in: .whitespaces))
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CreateGroupView(viewModel: GroupViewModel())
}

