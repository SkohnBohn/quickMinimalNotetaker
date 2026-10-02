import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var store = NotesStore()
    @FocusState private var focusedField: FocusField?
    @State private var sortByPage = false

    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var draggingID: UUID?
    @State private var dragOffsetY: CGFloat = 0

    /// Entries in reading order. Sorting is a display-only toggle: it never touches
    /// store.entries, so unchecking always restores the drag-arranged order.
    private var displayedEntries: [Entry] {
        guard sortByPage else { return store.entries }
        return store.entries.sorted { pageNumber($0) < pageNumber($1) }
    }

    private func pageNumber(_ entry: Entry) -> Int {
        Int(entry.page.trimmingCharacters(in: .whitespaces)) ?? .max
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text("NOTES")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.5)
                        .foregroundColor(.ink)

                    Spacer()

                    Button {
                        sortByPage.toggle()
                    } label: {
                        Rectangle()
                            .fill(sortByPage ? Color.ink : Color.clear)
                            .frame(width: 14, height: 14)
                            .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Menu {
                        Button("Save Notes…", action: saveNotesToFile)
                        Button("Load Notes…", action: loadNotesFromFile)
                    } label: {
                        Text("⇅")
                            .font(.system(size: 13))
                            .frame(width: 26, height: 26)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .foregroundColor(.ink)
                    .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))

                    Button {
                        createEntryAndReveal(using: proxy)
                    } label: {
                        Text("+")
                            .font(.system(size: 16))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.ink)
                    .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
                }
                .padding(EdgeInsets(top: 32, leading: 16, bottom: 10, trailing: 16))

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(displayedEntries) { entry in
                            EntryRow(
                                store: store,
                                entryID: entry.id,
                                focusedField: $focusedField,
                                allowReorder: !sortByPage,
                                isDragging: draggingID == entry.id,
                                dragOffsetY: dragOffsetY,
                                onDragChanged: { value in handleDragChanged(id: entry.id, value: value) },
                                onDragEnded: { value in handleDragEnded(id: entry.id, value: value) },
                                onReturnAdvance: { advanceFromText(entryID: entry.id, using: proxy) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .coordinateSpace(name: "entryList")
                    .onPreferenceChange(RowFramePreferenceKey.self) { rowFrames = $0 }
                }
            }
            .background(backgroundLayer)
            .frame(minWidth: 300, minHeight: 400)
            .focusable()
            .focused($focusedField, equals: .root)
            .onKeyPress(.return) {
                guard focusedField == .root else { return .ignored }
                createEntryAndReveal(using: proxy)
                return .handled
            }
            .onKeyPress(.upArrow) { moveSelection(by: -1, using: proxy) }
            .onKeyPress(.downArrow) { moveSelection(by: 1, using: proxy) }
            .onAppear {
                if focusedField == nil {
                    focusedField = .root
                }
            }
        }
    }

    /// Solid yellow with the reference painting bled in at low opacity on top, so the
    /// page still reads as yellow rather than as a picture with a tint.
    private var backgroundLayer: some View {
        ZStack {
            Color.appYellow
            if let backgroundImage {
                backgroundImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.33)
                    .clipped()
            }
        }
    }

    private var backgroundImage: Image? {
        guard let url = Bundle.module.url(forResource: "background", withExtension: "jpg"),
              let nsImage = NSImage(contentsOf: url)
        else { return nil }
        return Image(nsImage: nsImage)
    }

    /// The current user's Downloads folder — resolved per-user via FileManager, not a
    /// hardcoded path — used as the save/load panels' starting directory.
    private var defaultBackupDirectory: URL? {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    }

    /// Plain JSON of the entries array — the same shape NotesStore already persists,
    /// so a saved file can just be dropped back in to restore exactly.
    private func saveNotesToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "notes.json"
        panel.directoryURL = defaultBackupDirectory
        guard panel.runModal() == .OK, let url = panel.url,
              let data = try? JSONEncoder().encode(store.entries)
        else { return }
        try? data.write(to: url)
    }

    private func loadNotesFromFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.directoryURL = defaultBackupDirectory
        guard panel.runModal() == .OK, let url = panel.url,
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Entry].self, from: data)
        else { return }
        store.entries = decoded
        store.save()
    }

    private func createEntryAndReveal(using proxy: ScrollViewProxy) {
        let newID = store.addEntry()
        focusedField = .page(newID)
        // The new row doesn't exist in the scroll view's layout until after this
        // update commits, so scrollTo needs to run on the next run loop turn.
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(newID, anchor: .bottom)
            }
        }
    }

    /// Enter on a non-bullet line: move on to the next entry's page field, or add a new
    /// entry (and reveal it) if this was the last one.
    private func advanceFromText(entryID: UUID, using proxy: ScrollViewProxy) {
        let entries = displayedEntries
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
        if index + 1 < entries.count {
            let nextID = entries[index + 1].id
            focusedField = .page(nextID)
            withAnimation { proxy.scrollTo(nextID) }
        } else {
            createEntryAndReveal(using: proxy)
        }
    }

    /// Moves selection to the previous/next stop — each entry contributes a page-field
    /// stop and a text-field stop, in that order — and scrolls it into view. Only
    /// reachable when a page field, the delete button, or root holds focus: once arrow
    /// navigation lands on the text view, further arrow presses move the text cursor
    /// as normal rather than continuing to the next entry.
    private func moveSelection(by delta: Int, using proxy: ScrollViewProxy) -> KeyPress.Result {
        let stops: [FocusField] = displayedEntries.flatMap { [.page($0.id), .text($0.id)] }
        guard !stops.isEmpty else { return .ignored }

        let currentIndex = focusedField.flatMap { stops.firstIndex(of: $0) }
        let nextIndex = currentIndex.map { $0 + delta } ?? (delta > 0 ? 0 : stops.count - 1)
        guard stops.indices.contains(nextIndex) else { return .ignored }

        let target = stops[nextIndex]
        let targetID: UUID
        switch target {
        case .page(let id), .text(let id):
            targetID = id
        default:
            return .ignored
        }

        focusedField = target
        withAnimation {
            proxy.scrollTo(targetID)
        }
        return .handled
    }

    private func handleDragChanged(id: UUID, value: DragGesture.Value) {
        guard !sortByPage else { return }
        draggingID = id
        dragOffsetY = value.translation.height
    }

    private func handleDragEnded(id: UUID, value: DragGesture.Value) {
        defer {
            draggingID = nil
            dragOffsetY = 0
        }
        guard !sortByPage,
              let originFrame = rowFrames[id],
              let sourceIndex = store.entries.firstIndex(where: { $0.id == id })
        else { return }

        let droppedMidY = originFrame.midY + value.translation.height

        guard let targetEntry = store.entries.first(where: { entry in
            guard entry.id != id, let frame = rowFrames[entry.id] else { return false }
            return droppedMidY >= frame.minY && droppedMidY <= frame.maxY
        }), let targetIndex = store.entries.firstIndex(where: { $0.id == targetEntry.id }),
        targetIndex != sourceIndex
        else { return }

        store.move(
            fromOffsets: IndexSet(integer: sourceIndex),
            toOffset: targetIndex > sourceIndex ? targetIndex + 1 : targetIndex
        )
    }
}
