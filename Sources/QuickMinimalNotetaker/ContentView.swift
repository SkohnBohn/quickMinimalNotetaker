import SwiftUI

struct ContentView: View {
    @StateObject private var store = NotesStore()
    @FocusState private var focusedField: FocusField?
    @State private var sortByPage = false

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
                        EntryRow(store: store, entryID: entry.id, focusedField: $focusedField, allowReorder: !sortByPage)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color.appYellow)
        .frame(minWidth: 300, minHeight: 400)
    }
}
