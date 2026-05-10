import Foundation

private let balanceMoneyEpsilon = 0.02

// MARK: - Derived balance types (not persisted)

/// One pair-net row for Home / breakdown navigation.
struct Debt: Identifiable {
    let id: UUID = UUID()
    let debtor: Member
    let creditor: Member
    var amount: Double
    var expenseIds: [UUID] = []
}

/// Single contribution to a pair-net debt — one expense, signed from the debtor's perspective.
struct PairContribution: Identifiable {
    var id: UUID { expense.id }
    let expense: Expense
    let amount: Double
}

enum BalanceCalculatorService {

    /// Signed remainder for `memberId` toward the expense payer (`0` when member is payer).
    private static func signedRemainder(expense: Expense, memberId: UUID) -> Double {
        expense.signedBalanceTowardPayer(memberId: memberId)
    }

    /// Per-pair NET debts. One row per unordered pair {A,B}, signed so debtor → creditor.
    static func calculatePairwiseNetDebts(_ group: SplitGroup) -> [Debt] {
        var result: [Debt] = []
        let members = group.members

        for i in 0..<members.count {
            for j in (i + 1)..<members.count {
                let a = members[i]
                let b = members[j]

                var aOwesB: Double = 0
                var bOwesA: Double = 0
                var expenseIdSet = Set<UUID>()

                for expense in group.expenses {
                    let rA = signedRemainder(expense: expense, memberId: a.id)
                    let rB = signedRemainder(expense: expense, memberId: b.id)

                    if expense.paidByMemberId == b.id,
                       expense.participantRow(for: a.id) != nil {
                        if rA > balanceMoneyEpsilon {
                            aOwesB += rA
                            expenseIdSet.insert(expense.id)
                        } else if rA < -balanceMoneyEpsilon {
                            bOwesA += -rA
                            expenseIdSet.insert(expense.id)
                        }
                    }
                    if expense.paidByMemberId == a.id,
                       expense.participantRow(for: b.id) != nil {
                        if rB > balanceMoneyEpsilon {
                            bOwesA += rB
                            expenseIdSet.insert(expense.id)
                        } else if rB < -balanceMoneyEpsilon {
                            aOwesB += -rB
                            expenseIdSet.insert(expense.id)
                        }
                    }
                }

                let net = aOwesB - bOwesA
                if abs(net) < balanceMoneyEpsilon { continue }

                let sortedIds = expenseIdSet.sorted { $0.uuidString < $1.uuidString }
                if net > 0 {
                    result.append(Debt(debtor: a, creditor: b, amount: net, expenseIds: sortedIds))
                } else {
                    result.append(Debt(debtor: b, creditor: a, amount: -net, expenseIds: sortedIds))
                }
            }
        }

        return result.sorted { $0.amount > $1.amount }
    }

    static func pairContributions(group: SplitGroup, debtor: Member, creditor: Member) -> [PairContribution] {
        var results: [PairContribution] = []
        for expense in group.expenses {
            let rD = signedRemainder(expense: expense, memberId: debtor.id)
            let rC = signedRemainder(expense: expense, memberId: creditor.id)

            if expense.paidByMemberId == creditor.id,
               expense.participantRow(for: debtor.id) != nil,
               abs(rD) > balanceMoneyEpsilon {
                results.append(PairContribution(expense: expense, amount: rD))
            }
            if expense.paidByMemberId == debtor.id,
               expense.participantRow(for: creditor.id) != nil,
               abs(rC) > balanceMoneyEpsilon {
                results.append(PairContribution(expense: expense, amount: -rC))
            }
        }
        return results.sorted { $0.expense.date > $1.expense.date }
    }
}
