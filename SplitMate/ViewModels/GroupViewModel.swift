import Foundation
import Combine

class GroupViewModel: ObservableObject {
    @Published var groups: [SplitGroup] = [] {
        didSet { GroupStorageService.shared.save(groups: groups) }
    }

    init() {
        self.groups = GroupStorageService.shared.load()
    }

    func addGroup(name: String) {
        let group = SplitGroup(id: UUID(), name: name, members: [], expenses: [], createdAt: Date())
        groups.append(group)
    }

    func addMember(toGroupId: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let idx = groups.firstIndex(where: { $0.id == toGroupId }) else { return }
        groups[idx].members.append(Member(id: UUID(), name: trimmed))
    }
}
