import SwiftUI

struct GroupDetailView: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0
    @State private var showingAddExpense = false
    @State private var showingFilterSheet = false
    @State private var expenseFilter: ExpenseFilter = .empty

    private var group: SplitGroup? {
        viewModel.groups.first { $0.id == groupId }
    }

    var body: some View {
        if let group = group {
            TabView(selection: $selectedTab) {
                GroupHomeTab(
                    viewModel: viewModel,
                    groupId: groupId,
                    selectedTab: $selectedTab
                )
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

                GroupExpensesTab(
                    viewModel: viewModel,
                    groupId: groupId,
                    showingAddExpense: $showingAddExpense,
                    filter: $expenseFilter
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
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            showingFilterSheet = true
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(expenseFilter.isActive ? Color.appTerra : Color.appWhite)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 9)
                                            .stroke(expenseFilter.isActive ? Color.appTerra : Color.appBorder, lineWidth: 1)
                                    )
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(expenseFilter.isActive ? .white : .appText)
                            }
                            .frame(width: 30, height: 30)
                        }
                        .accessibilityLabel("Filter expenses")

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
            .sheet(isPresented: $showingFilterSheet) {
                ExpenseFilterSheet(filter: $expenseFilter, members: group.members)
                    .presentationDetents([.medium, .large])
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
