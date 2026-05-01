import SwiftUI

struct GroupsView: View {
    @StateObject private var viewModel = GroupViewModel()
    @State private var showingAddGroup = false
    @State private var newGroupName = ""

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.groups.isEmpty {
                    Text("No groups yet. Start by adding a group!")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(viewModel.groups) { group in
                        NavigationLink(destination: GroupDetailView(viewModel: viewModel, groupId: group.id)) {
                            VStack(alignment: .leading) {
                                Text(group.name).font(.headline)
                                Text("Members: \(group.members.count)").font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("SplitMate")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGroup = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                CreateGroupView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    GroupsView()
}
