import SwiftUI
import AppKit

/// An NSTextView that reports its natural height so SwiftUI can grow the row to fit,
/// mirroring an auto-resizing <textarea>.
final class GrowingTextView: NSTextView {
    override var intrinsicContentSize: NSSize {
        guard let layoutManager, let textContainer else {
            return super.intrinsicContentSize
        }
        layoutManager.ensureLayout(for: textContainer)
        let usedHeight = layoutManager.usedRect(for: textContainer).height
        return NSSize(width: NSView.noIntrinsicMetric, height: max(usedHeight, 20))
    }

    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }
}

/// Plain multi-line text editor with lightweight bullet formatting: pressing Enter on a
/// line starting with "- " continues the bullet on the next line; pressing Enter on an
/// empty bullet line removes it instead of repeating it. Pressing Enter on a non-bullet
/// line, or Tab/Shift-Tab anywhere, hands focus onward instead of inserting text.
struct BulletTextView: NSViewRepresentable {
    @Binding var text: String
    var onReturnAdvance: () -> Void = {}

    func makeNSView(context: Context) -> GrowingTextView {
        let textView = GrowingTextView()
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = .systemFont(ofSize: 13)
        textView.textColor = .black
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        return textView
    }

    func updateNSView(_ nsView: GrowingTextView, context: Context) {
        context.coordinator.parent = self
        if nsView.string != text {
            nsView.string = text
            nsView.invalidateIntrinsicContentSize()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: BulletTextView

        init(_ parent: BulletTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                textView.window?.selectNextKeyView(nil)
                return true
            }
            if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
                textView.window?.selectPreviousKeyView(nil)
                return true
            }
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }

            let value = textView.string as NSString
            let cursor = textView.selectedRange().location
            let lineRange = value.lineRange(for: NSRange(location: cursor, length: 0))
            let currentLine = value.substring(with: NSRange(location: lineRange.location, length: cursor - lineRange.location))

            guard currentLine.range(of: #"^\s*-\s?"#, options: .regularExpression) != nil else {
                // Not on a bullet line: Enter finishes this field and moves on, like Tab.
                parent.onReturnAdvance()
                return true
            }

            let indent = String(currentLine.prefix { $0 == " " || $0 == "\t" })

            if currentLine.trimmingCharacters(in: .whitespaces) == "-" {
                let removalRange = NSRange(location: lineRange.location, length: cursor - lineRange.location)
                textView.insertText("", replacementRange: removalRange)
            } else {
                textView.insertText("\n" + indent + "- ", replacementRange: textView.selectedRange())
            }

            parent.text = textView.string
            return true
        }
    }
}
