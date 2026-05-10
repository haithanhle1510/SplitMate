import Foundation

enum ExpenseSplitType: String, Codable, CaseIterable {
    case equal
    case percentage
    case exactAmount

    var displayLabel: String {
        switch self {
        case .equal: return "Split equally"
        case .percentage: return "Split by percentage"
        case .exactAmount: return "Split by exact amounts"
        }
    }

    var shortLabel: String {
        switch self {
        case .equal:       return "Equally"
        case .percentage:  return "By %"
        case .exactAmount: return "By Amount"
        }
    }
}
