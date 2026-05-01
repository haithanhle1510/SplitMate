import Foundation

enum CurrencyFormatter {
    static func format(_ amount: Double) -> String {
        let abs = amount.magnitude
        let whole = abs.truncatingRemainder(dividingBy: 1) == 0
        return whole ? String(format: "$%.0f", abs) : String(format: "$%.2f", abs)
    }
}
