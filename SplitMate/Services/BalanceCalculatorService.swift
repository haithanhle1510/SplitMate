import Foundation

class BalanceCalculatorService {
    // MARK: - Direct Debts (Original - No Simplification)
    
    /// Calculate direct debts from expenses (before any simplification)
    static func calculateDirectDebts(_ group: SplitGroup) -> [Debt] {
        var directDebts: [Debt] = []
        
        // For each pair of members
        for debtor in group.members {
            for creditor in group.members {
                if debtor.id == creditor.id { continue }
                
                // Find all expenses where creditor paid and debtor participated
                var totalShare: Double = 0
                var contributingExpenseIds: [UUID] = []
                
                for expense in group.expenses {
                    if expense.paidBy == creditor.id && 
                       expense.participantIds.contains(debtor.id) {
                        totalShare += expense.perPersonShare
                        contributingExpenseIds.append(expense.id)
                    }
                }
                
                // Only create debt if there's an amount owed
                if totalShare > 0.01 {
                    directDebts.append(Debt(
                        debtor: debtor,
                        creditor: creditor,
                        amount: totalShare,
                        expenseIds: contributingExpenseIds
                    ))
                }
            }
        }
        
        return directDebts.sorted { $0.amount > $1.amount }
    }
    
    // MARK: - Simplified Debts (Greedy Algorithm)
    
    /// Calculate simplified debts using greedy algorithm (recommended for display)
    static func calculateSimplifiedDebts(_ group: SplitGroup) -> [Debt] {
        // 1. Calculate member balances
        let memberBalances = calculateMemberBalances(group)
        
        // 2. Separate creditors (owed money) and debtors (owe money)
        let creditors = memberBalances.filter { $0.balance > 0.01 }  // Use small tolerance for floating point
        var debtors = memberBalances.filter { $0.balance < -0.01 }
        
        // 3. Greedy matching - pair creditors with debtors
        var debts: [Debt] = []
        
        for creditorIdx in 0..<creditors.count {
            var creditorRemaining = creditors[creditorIdx].balance
            
            for debtorIdx in 0..<debtors.count {
                if creditorRemaining < 0.01 { break }
                
                let debtorOwing = abs(debtors[debtorIdx].balance)
                if debtorOwing < 0.01 { continue }
                
                let settlement = min(creditorRemaining, debtorOwing)
                
                debts.append(Debt(
                    debtor: debtors[debtorIdx].member,
                    creditor: creditors[creditorIdx].member,
                    amount: settlement,
                    expenseIds: []  // Simplified debts don't track specific expenses
                ))
                
                creditorRemaining -= settlement
                debtors[debtorIdx].balance += settlement  // Make it less negative
            }
        }
        
        return debts
    }
    
    // MARK: - Backward Compatibility
    
    /// Legacy method - calls simplified debts for backward compatibility
    static func calculateGroupDebts(_ group: SplitGroup) -> [Debt] {
        return calculateSimplifiedDebts(group)
    }
    
    // MARK: - Helper Methods
    
    /// Get expenses for a debt (for displaying in dropdown)
    static func getExpensesForDebt(_ debt: Debt, group: SplitGroup) -> [Expense] {
        return group.expenses.filter { debt.expenseIds.contains($0.id) }
    }
    
    // Calculate balance for each member in a group
    static func calculateMemberBalances(_ group: SplitGroup) -> [MemberBalance] {
        var memberBalances: [UUID: Double] = [:]
        
        // Initialize all members with 0 balance
        group.members.forEach { memberBalances[$0.id] = 0 }
        
        // Process each expense
        for expense in group.expenses {
            let share = expense.perPersonShare
            let payer = expense.paidBy
            
            // Payer gets credit for paying
            memberBalances[payer, default: 0] += expense.amount
            
            // Deduct share from each participant
            for participant in expense.participantIds {
                memberBalances[participant, default: 0] -= share
            }
        }
        
        // Convert to MemberBalance objects
        return group.members.map { member in
            let balance = memberBalances[member.id] ?? 0
            return MemberBalance(
                id: member.id,
                member: member,
                balance: balance,
                debts: []  // Debts calculated separately per member if needed
            )
        }.sorted { $0.balance > $1.balance }  // Sort: creditors first
    }
}

