import SwiftUI

struct ContentView: View {
    @StateObject private var store = NotesStore()
    @FocusState private var focusedField: FocusField?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("NOTES")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(.ink)

                Spacer()

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
                    ForEach(store.entries) { entry in
                        EntryRow(store: store, entryID: entry.id, focusedField: $focusedField)
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
