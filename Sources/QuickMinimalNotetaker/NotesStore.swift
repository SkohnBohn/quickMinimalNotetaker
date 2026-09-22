import Foundation
import Combine

final class NotesStore: ObservableObject {
    @Published var entries: [Entry] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("QuickMinimalNotetaker", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("notes.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        entries = (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func addEntry() {
        entries.append(Entry())
        save()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func move(sourceID: UUID, targetID: UUID) {
        guard sourceID != targetID,
              let fromIndex = entries.firstIndex(where: { $0.id == sourceID }),
              let toIndex = entries.firstIndex(where: { $0.id == targetID })
        else { return }
        let moved = entries.remove(at: fromIndex)
        let insertIndex = entries.firstIndex(where: { $0.id == targetID }) ?? toIndex
        entries.insert(moved, at: insertIndex)
        save()
    }
}
