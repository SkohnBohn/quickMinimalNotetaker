import SwiftUI
import AppKit

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

                Button {
                    let newID = store.addEntry()
                    focusedField = .page(newID)
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
                            onDragEnded: { value in handleDragEnded(id: entry.id, value: value) }
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
                    .opacity(0.2)
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
