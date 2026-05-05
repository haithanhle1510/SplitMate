import Foundation

enum ExpenseCategory: String, Codable, CaseIterable {
    case food = "food"
    case travel = "travel"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case bills = "bills"
    case other = "other"

    var displayName: String {
        switch self {
        case .food:          return "Food"
        case .travel:        return "Travel"
        case .shopping:      return "Shopping"
        case .entertainment: return "Entertainment"
        case .bills:         return "Bills"
        case .other:         return "Other"
        }
    }

    var emoji: String {
        switch self {
        case .food:          return "🍔"
        case .travel:        return "✈️"
        case .shopping:      return "🛍️"
        case .entertainment: return "🎬"
        case .bills:         return "💡"
        case .other:         return "📦"
        }
    }
}
