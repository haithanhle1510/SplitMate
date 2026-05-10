import SwiftUI

struct GroupExpensesTab: View {
    @ObservedObject var viewModel: GroupViewModel
    let groupId: UUID
    @Binding var showingAddExpense: Bool
    @Binding var filter: ExpenseFilter

    private var group: SplitGroup? { viewModel.groups.first { $0.id == groupId } }

    private func filteredExpenses(_ group: SplitGroup) -> [Expense] {
        guard filter.isActive else { return group.expenses }
        return group.expenses.filter { filter.matches($0) }
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            if let group {
                if group.expenses.isEmpty {
                    emptyState
                } else {
                    let visible = filteredExpenses(group)
                    VStack(spacing: 0) {
                        if filter.isActive {
                            filterChipBar(group: group)
                        }
                        if visible.isEmpty {
                            filteredEmptyState
                        } else {
                            expenseList(expenses: visible, group: group)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty states

    private var emptyState: some View {
        EmptyStateView(
            emoji: "🧾",
            title: "No expenses yet",
            message: "When something is shared, log it here.",
            ctaLabel: "Add expense",
            onCtaTap: { showingAddExpense = true }
        )
    }

    private var filteredEmptyState: some View {
        VStack(spacing: 10) {
            Text("🔍")
                .font(.system(size: 36))
            Text("Nothing matches")
                .font(.nunito(16, weight: .heavy))
                .foregroundColor(.appText)
            Text("Clear the filter to show every expense.")
                .font(.nunito(13, weight: .semibold))
                .foregroundColor(.appMuted)
                .multilineTextAlignment(.center)
            Button {
                filter = .empty
            } label: {
                Text("Clear filter")
                    .font(.nunito(13, weight: .heavy))
                    .foregroundColor(.appTerra)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(Capsule().stroke(Color.appTerra, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Chip bar

    private func filterChipBar(group: SplitGroup) -> some View {
        let memberChips: [(String, () -> Void)] = filter.memberIds.compactMap { id in
            guard let m = group.members.first(where: { $0.id == id }) else { return nil }
            return (m.name, { filter.memberIds.remove(id) })
        }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(memberChips.enumerated()), id: \.offset) { _, chip in
                    activeChip(label: chip.0, onRemove: chip.1)
                }
                if filter.unsettledOnly {
                    activeChip(label: "Unsettled", onRemove: { filter.unsettledOnly = false })
                }
                Button {
                    filter = .empty
                } label: {
                    Text("Clear")
                        .font(.nunito(12, weight: .heavy))
                        .foregroundColor(.appMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear all filters")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.appBg)
        .overlay(Rectangle().fill(Color.appBorder).frame(height: 1), alignment: .bottom)
    }

    private func activeChip(label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.nunito(12, weight: .heavy))
                .foregroundColor(.appTerra)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.appTerra)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(label) filter")
        }
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .background(Color.appPeach.opacity(0.5))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appTerra, lineWidth: 1))
    }

    // MARK: - Expense list

    private func expenseList(expenses: [Expense], group: SplitGroup) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(expenses) { expense in
                    NavigationLink {
                        ExpenseDetailView(viewModel: viewModel, groupId: groupId, expenseId: expense.id)
                            .navigationTitle(expense.title)
                    } label: {
                        ExpenseRowView(expense: expense, group: group)
                    }
                    .buttonStyle(.plain)

                    if expense.id != expenses.last?.id {
                        Divider()
                            .background(Color.appBorder)
                            .padding(.leading, ExpenseRowView.dividerLeadingInset)
                    }
                }
            }
            .background(Color.appWhite)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Expense row

struct ExpenseRowView: View {
    let expense: Expense
    let group: SplitGroup

    static let dateColumnWidth: CGFloat = 40
    private static let contentGap: CGFloat = 12
    static let rowHorizontalPadding: CGFloat = 16

    /// Leading inset so dividers align with the title column (matches row layout).
    static var dividerLeadingInset: CGFloat {
        rowHorizontalPadding + dateColumnWidth + contentGap
    }

    private var payerName: String {
        group.members.first { $0.id == expense.paidByMemberId }?.name ?? "Unknown"
    }

    private var detailLine: String {
        "Paid by \(payerName) · \(expense.splitType.displayLabel)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: Self.contentGap) {
            VStack(spacing: 2) {
                Text(expense.date.dayString)
                    .font(.nunito(18, weight: .heavy))
                    .foregroundColor(.appText)
                Text(expense.date.monthShortString)
                    .font(.nunito(11, weight: .semibold))
                    .foregroundColor(.appMuted)
            }
            .frame(width: Self.dateColumnWidth, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.nunito(15, weight: .heavy))
                    .foregroundColor(.appText)
                Text(detailLine)
                    .font(.nunito(12, weight: .semibold))
                    .foregroundColor(.appMuted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(CurrencyFormatter.format(expense.totalAmount))
                .font(.nunito(15, weight: .heavy))
                .foregroundColor(.appTerra)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, Self.rowHorizontalPadding)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(expense.title), \(detailLine), \(CurrencyFormatter.format(expense.totalAmount))")
    }
}
