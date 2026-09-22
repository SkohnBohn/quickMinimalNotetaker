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

    @discardableResult
    func addEntry() -> UUID {
        let entry = Entry()
        entries.append(entry)
        save()
        return entry.id
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        entries.move(fromOffsets: source, toOffset: destination)
        save()
    }
}

private extension Array {
    /// Same contract as the standard List `onMove` helper: moves the elements at
    /// `source` so the first of them ends up at `destination`, shifting the rest
    /// of the array accordingly.
    mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let itemsToMove = source.map { self[$0] }
        for index in source.sorted(by: >) {
            remove(at: index)
        }
        let adjustedDestination = destination - source.filter { $0 < destination }.count
        insert(contentsOf: itemsToMove, at: Swift.max(0, Swift.min(adjustedDestination, count)))
    }
}
