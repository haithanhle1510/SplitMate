import Foundation
import Combine

class GroupViewModel: ObservableObject {
    // The groups managed by this view model
    @Published var groups: [Group] = []
    
    // For demo: basic initializer with test data
    init() {
        // For now, create an empty list; can load from storage later
        self.groups = []
    }
    
    // Add a new group
    func addGroup(name: String) {
        let group = Group(id: UUID(), name: name, members: [], expenses: [], createdAt: Date())
        groups.append(group)
        // Persist change in future
    }
}
