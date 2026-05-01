import SwiftUI

struct GroupDetailView: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @State private var showingAddMember = false

    private var group: SplitGroup? {
        viewModel.groups.first { $0.id == groupId }
    }

    var body: some View {
        if let group = group {
            List {
                Section(header: Text("Members")) {
                    if group.members.isEmpty {
                        Text("No members yet").foregroundColor(.secondary)
                    } else {
                        ForEach(group.members) { member in
                            Text(member.name)
                        }
                    }
                }
                Section(header: Text("Expenses")) {
                    Text("No expenses yet").foregroundColor(.secondary)
                }
            }
            .navigationTitle(group.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMember = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddMemberView(viewModel: viewModel, groupId: groupId)
            }
        } else {
            Text("Group not found").foregroundColor(.secondary)
        }
    }
}
