import SwiftUI

struct EntryRow: View {
    @ObservedObject var store: NotesStore
    let entryID: UUID
    var focusedField: FocusState<FocusField?>.Binding
    var allowReorder: Bool = true

    var body: some View {
        if store.entries.contains(where: { $0.id == entryID }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    TextField("", text: pageBinding)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(width: 40, height: 28)
                        .overlay(Rectangle().frame(width: 1).foregroundColor(.ink), alignment: .trailing)
                        .focused(focusedField, equals: .page(entryID))
                        .onSubmit {
                            focusedField.wrappedValue = .text(entryID)
                        }

                    Spacer(minLength: 0)

                    Button {
                        store.remove(id: entryID)
                    } label: {
                        Text("×")
                            .font(.system(size: 14))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.ink.opacity(0.45))
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.ink), alignment: .leading)
                    .focused(focusedField, equals: .delete(entryID))
                }
                .frame(height: 28)
                .overlay(Rectangle().frame(height: 1).foregroundColor(.ink), alignment: .bottom)

                BulletTextView(text: textBinding, onReturnAdvance: advanceFromText)
                    .focused(focusedField, equals: .text(entryID))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minHeight: 34)
            }
            .background(dragHandle)
            .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
            .padding(.bottom, 10)
            .onDrop(of: [.text], isTargeted: nil) { providers in
                guard allowReorder, let provider = providers.first else { return false }
                _ = provider.loadObject(ofClass: NSString.self) { reading, _ in
                    guard let string = reading as? String, let sourceID = UUID(uuidString: string) else { return }
                    DispatchQueue.main.async {
                        store.move(sourceID: sourceID, targetID: entryID)
                    }
                }
                return true
            }
        }
    }

    /// The card's own background, doubling as the drag-to-reorder handle. Attaching
    /// onDrag here (instead of on the whole card) keeps it from swallowing clicks meant
    /// for the page field, the delete button, or the text view.
    @ViewBuilder
    private var dragHandle: some View {
        if allowReorder {
            Color.appYellow.onDrag {
                NSItemProvider(object: entryID.uuidString as NSString)
            }
        } else {
            Color.appYellow
        }
    }

    private func advanceFromText() {
        guard let index = store.entries.firstIndex(where: { $0.id == entryID }) else { return }
        if index + 1 < store.entries.count {
            focusedField.wrappedValue = .page(store.entries[index + 1].id)
        } else {
            let newID = store.addEntry()
            focusedField.wrappedValue = .page(newID)
        }
    }

    // Looked up by id on every access (not a captured array index) so a binding held by
    // an outgoing view during removal can't read or write past the end of the array.
    private var pageBinding: Binding<String> {
        Binding(
            get: { store.entries.first(where: { $0.id == entryID })?.page ?? "" },
            set: { newValue in
                guard let idx = store.entries.firstIndex(where: { $0.id == entryID }) else { return }
                store.entries[idx].page = newValue
                store.save()
            }
        )
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { store.entries.first(where: { $0.id == entryID })?.text ?? "" },
            set: { newValue in
                guard let idx = store.entries.firstIndex(where: { $0.id == entryID }) else { return }
                store.entries[idx].text = newValue
                store.save()
            }
        )
    }
}
