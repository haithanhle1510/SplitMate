import Foundation

/// Defines how `owedAmount` is computed when creating an expense (not persisted).
enum ExpenseSplitPayload {
    case equal(participantIds: [UUID])
    case percentage(parts: [(memberId: UUID, percentage: Double)])
    case exact(parts: [(memberId: UUID, amount: Double)])
}
