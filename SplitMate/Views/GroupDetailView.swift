import SwiftUI

struct GroupDetailView: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0
    @State private var showingAddExpense = false

    private var group: SplitGroup? {
        viewModel.groups.first { $0.id == groupId }
    }

    var body: some View {
        if let group = group {
            TabView(selection: $selectedTab) {
                GroupHomeTab(viewModel: viewModel, groupId: groupId, selectedTab: $selectedTab)
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)

                GroupExpensesTab(
                    viewModel: viewModel,
                    groupId: groupId,
                    showingAddExpense: $showingAddExpense
                )
                .tabItem { Label("Expenses", systemImage: "list.bullet.rectangle") }
                .tag(1)

                GroupSettingsTab(
                    viewModel: viewModel,
                    groupId: groupId,
                    onGroupDeleted: { dismiss() }
                )
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)
            }
            .tint(.appTerra)
            .navigationTitle(currentTitle(groupName: group.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if selectedTab == 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddExpense = true
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9).fill(Color.appTerra)
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 30, height: 30)
                        }
                        .accessibilityLabel("Add expense")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(viewModel: viewModel, groupId: groupId)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        } else {
            Text("Group not found").foregroundColor(.secondary)
        }
    }

    private func currentTitle(groupName: String) -> String {
        switch selectedTab {
        case 1: return "Expenses"
        case 2: return "Settings"
        default: return groupName
        }
    }
}
