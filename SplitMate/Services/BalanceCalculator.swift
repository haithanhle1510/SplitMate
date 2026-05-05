//
//  BalanceCalculator.swift
//  SplitMate
//
//  Created by Hai Thanh Le on 27/4/2026.
//

import Foundation

class BalanceCalculator {
    func getAllExpenses() -> [Expense] {
        return []
    }
    func calculateBalances() -> [String: Double] {
        let expenses = getAllExpenses()
        var balances: [String: Double] = [:]

        for expense in expenses {
            let amountPerPerson = expense.amount / Double(expense.participants.count)
            for participant in expense.participants {
                balances[participant, default: 0.0] += amountPerPerson
            }
        }
        return balances
    }
}

