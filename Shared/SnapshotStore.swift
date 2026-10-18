import Foundation

/// The snapshot file in the App Group container shared by the app and the widget.
enum SnapshotStore {
    static var groupID: String? {
        Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String
    }

    private static var fileURL: URL? {
        guard let groupID,
              let container = FileManager.default.containerURL(
                  forSecurityApplicationGroupIdentifier: groupID)
        else { return nil }
        return container.appendingPathComponent("snapshot.json")
    }

    static func load() -> Snapshot {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? decoder.decode(Snapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    static func save(_ snapshot: Snapshot) {
        guard let url = fileURL, let data = try? encoder.encode(snapshot) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
