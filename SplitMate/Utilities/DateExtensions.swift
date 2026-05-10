import Foundation

extension Date {
    /// Format date as "MMM d" (e.g., "Apr 29")
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// Day-of-month as a string (e.g., "29")
    var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: self)
    }

    /// Short month name (e.g., "Apr")
    var monthShortString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: self)
    }
}
