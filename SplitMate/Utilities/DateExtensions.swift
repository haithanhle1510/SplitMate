import Foundation

extension Date {
    /// Format date as "MMM d" (e.g., "Apr 29")
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}
