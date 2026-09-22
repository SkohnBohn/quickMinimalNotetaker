import SwiftUI
import AppKit

struct EntryRow: View {
    @ObservedObject var store: NotesStore
    let entryID: UUID
    var focusedField: FocusState<FocusField?>.Binding
    var allowReorder: Bool = true
    var isDragging: Bool = false
    var dragOffsetY: CGFloat = 0
    var onDragChanged: (DragGesture.Value) -> Void = { _ in }
    var onDragEnded: (DragGesture.Value) -> Void = { _ in }

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
                            .contentShape(Rectangle())
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
            .offset(y: isDragging ? dragOffsetY : 0)
            .opacity(isDragging ? 0.85 : 1)
            .zIndex(isDragging ? 1 : 0)
            .animation(isDragging ? nil : .easeOut(duration: 0.15), value: dragOffsetY)
        }
    }

    /// The card's own background, doubling as the drag-to-reorder handle and reporting
    /// this row's on-screen frame so a drag elsewhere can tell it's crossed this row.
    /// A plain DragGesture (not onDrag/NSItemProvider) is used because pasteboard-based
    /// drag sessions are unreliable for same-window reordering on macOS.
    @ViewBuilder
    private var dragHandle: some View {
        GeometryReader { geo in
            if allowReorder {
                entryBackground
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 4, coordinateSpace: .named("entryList"))
                            .onChanged(onDragChanged)
                            .onEnded(onDragEnded)
                    )
                    .preference(key: RowFramePreferenceKey.self, value: [entryID: geo.frame(in: .named("entryList"))])
            } else {
                entryBackground
                    .preference(key: RowFramePreferenceKey.self, value: [entryID: geo.frame(in: .named("entryList"))])
            }
        }
    }

    private var entryBackground: some View {
        ZStack {
            Color.appYellow
            if let entryImage {
                // .fit (not .fill): every card shows the whole picture, independently,
                // clipped to just its own bounds — rows of differing height would
                // otherwise each crop a different zoomed sliver, reading as one image
                // flowing continuously behind the whole list instead of a background
                // that belongs to each card on its own.
                entryImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(0.15)
                    .clipped()
            }
        }
    }

    private var entryImage: Image? {
        guard let url = Bundle.module.url(forResource: "entry_background", withExtension: "png"),
              let nsImage = NSImage(contentsOf: url)
        else { return nil }
        return Image(nsImage: nsImage)
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
