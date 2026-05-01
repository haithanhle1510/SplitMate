import SwiftUI

struct GroupsView: View {
    @StateObject private var viewModel = GroupViewModel()
    @State private var showingAddGroup = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                if viewModel.groups.isEmpty {
                    EmptyStateView(
                        emoji: "👥",
                        title: "No groups yet.",
                        message: "Tap + to start splitting."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.groups) { group in
                                NavigationLink {
                                    GroupDetailView(viewModel: viewModel, groupId: group.id)
                                } label: {
                                    GroupCardView(group: group)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SplitMate")
                        .font(.nunito(18, weight: .heavy))
                        .foregroundColor(.appText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddGroup = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.appTerra)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Create new group")
                }
            }
            .toolbarBackground(Color.appBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingAddGroup) {
                CreateGroupView(viewModel: viewModel)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    GroupsView()
}
