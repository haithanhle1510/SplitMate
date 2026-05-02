import Foundation
import Combine

enum RemoveMemberResult {
    case removed
    case blockedByExpenses
    case notFound
}

class GroupViewModel: ObservableObject {
    @Published var groups: [SplitGroup] = [] {
        didSet { GroupStorageService.shared.save(groups: groups) }
    }

    init() {
        self.groups = GroupStorageService.shared.load()
    }

    func addGroup(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let group = SplitGroup(id: UUID(), name: trimmed, members: [], expenses: [], createdAt: Date())
        groups.append(group)
    }

    func renameGroup(id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let idx = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[idx].name = trimmed
    }

    func deleteGroup(id: UUID) {
        groups.removeAll { $0.id == id }
    }

    func addMember(toGroupId: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let idx = groups.firstIndex(where: { $0.id == toGroupId }) else { return }
        groups[idx].members.append(Member(id: UUID(), name: trimmed))
    }

    func removeMember(fromGroupId: UUID, memberId: UUID) -> RemoveMemberResult {
        guard let idx = groups.firstIndex(where: { $0.id == fromGroupId }) else {
            return .notFound
        }
        let isReferencedInExpenses = groups[idx].expenses.contains { exp in
            exp.paidBy == memberId || exp.participantIds.contains(memberId)
        }
        if isReferencedInExpenses {
            return .blockedByExpenses
        }
        groups[idx].members.removeAll { $0.id == memberId }
        return .removed
    }
}
