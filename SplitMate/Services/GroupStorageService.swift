import Foundation

class GroupStorageService {
    static let shared = GroupStorageService()
    private let filename = "groups.json"

    private init() {}

    func save(groups: [SplitGroup]) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(groups)
            if let url = getFileURL() {
                try data.write(to: url)
            }
        } catch {
            print("Failed to save groups: \(error)")
        }
    }

    func load() -> [SplitGroup] {
        guard let url = getFileURL(),
              FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let groups = try decoder.decode([SplitGroup].self, from: data)
            return groups
        } catch {
            print("Failed to load groups: \(error)")
            return []
        }
    }

    private func getFileURL() -> URL? {
        let fm = FileManager.default
        guard let documentsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(filename)
    }
}
