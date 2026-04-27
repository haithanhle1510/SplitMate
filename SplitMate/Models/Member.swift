import Foundation

struct Member: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
}
