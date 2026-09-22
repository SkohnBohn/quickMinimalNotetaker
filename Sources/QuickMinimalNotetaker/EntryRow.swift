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
                entryBackground(size: geo.size)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 4, coordinateSpace: .named("entryList"))
                            .onChanged(onDragChanged)
                            .onEnded(onDragEnded)
                    )
                    .preference(key: RowFramePreferenceKey.self, value: [entryID: geo.frame(in: .named("entryList"))])
            } else {
                entryBackground(size: geo.size)
                    .preference(key: RowFramePreferenceKey.self, value: [entryID: geo.frame(in: .named("entryList"))])
            }
        }
    }

    /// Scales the image to exactly the card's width — the same scale for every card,
    /// regardless of that card's own height — then anchors it to the top and clips off
    /// whatever doesn't fit. Rows just show more or less of the same top slice at the
    /// same zoom, instead of each stretching/zooming the picture to its own aspect ratio.
    private func entryBackground(size: CGSize) -> some View {
        ZStack(alignment: .top) {
            Color.appYellow
            if let nsImage = Self.entryNSImage, nsImage.size.width > 0 {
                let scale = size.width / nsImage.size.width
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: size.width, height: nsImage.size.height * scale)
                    .offset(y: -30)
                    .opacity(0.23)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .clipped()
    }

    private static let entryNSImage: NSImage? = {
        guard let url = Bundle.module.url(forResource: "entry_background", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }()

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
