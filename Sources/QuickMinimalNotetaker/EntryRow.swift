import SwiftUI

struct EntryRow: View {
    @ObservedObject var store: NotesStore
    let entryID: UUID

    var body: some View {
        if let index = store.entries.firstIndex(where: { $0.id == entryID }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    TextField("", text: pageBinding(index))
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(width: 40, height: 28)
                        .overlay(Rectangle().frame(width: 1).foregroundColor(.ink), alignment: .trailing)

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
                }
                .frame(height: 28)
                .overlay(Rectangle().frame(height: 1).foregroundColor(.ink), alignment: .bottom)

                BulletTextView(text: textBinding(index))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minHeight: 34)
            }
            .background(Color.appYellow)
            .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
            .padding(.bottom, 10)
            .onDrag {
                NSItemProvider(object: entryID.uuidString as NSString)
            }
            .onDrop(of: [.text], isTargeted: nil) { providers in
                guard let provider = providers.first else { return false }
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

    private func pageBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { store.entries[index].page },
            set: { newValue in
                store.entries[index].page = newValue
                store.save()
            }
        )
    }

    private func textBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { store.entries[index].text },
            set: { newValue in
                store.entries[index].text = newValue
                store.save()
            }
        )
    }
}
