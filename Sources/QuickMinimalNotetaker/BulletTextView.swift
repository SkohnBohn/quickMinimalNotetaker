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

    // AppKit's Shift+Return → insertNewlineIgnoringFieldEditor: binding only kicks in
    // when a text view is acting as a field editor for some other control. This view
    // is a standalone NSTextView, so Shift+Return would otherwise resolve to the exact
    // same insertNewline: as plain Return, and the delegate could never tell them apart.
    // Checking the modifier here, before interpretKeyEvents/doCommandBy ever see it, is
    // the only reliable way to catch it.
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36, event.modifierFlags.contains(.shift) {
            insertText("\n", replacementRange: selectedRange())
            return
        }
        super.keyDown(with: event)
    }
}

/// Plain multi-line text editor with lightweight bullet formatting: pressing Enter on a
/// line starting with "- " continues the bullet on the next line; pressing Enter on an
/// empty bullet line removes it instead of repeating it. Pressing Enter on a non-bullet
/// line advances to the next entry (or creates one) instead of inserting a newline —
/// use Shift+Enter for a literal line break. Tab/Shift-Tab hand focus to the next/
/// previous control.
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
            // Defensive fallback: GrowingTextView.keyDown is what actually catches
            // Shift+Return (see its comment for why), but this selector is kept here
            // too in case some other input path ever produces it.
            if commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
                textView.insertText("\n", replacementRange: textView.selectedRange())
                parent.text = textView.string
                return true
            }
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }

            let value = textView.string as NSString
            let cursor = textView.selectedRange().location
            let lineRange = value.lineRange(for: NSRange(location: cursor, length: 0))
            let currentLine = value.substring(with: NSRange(location: lineRange.location, length: cursor - lineRange.location))

            guard currentLine.range(of: #"^\s*-\s?"#, options: .regularExpression) != nil else {
                // Not on a bullet line: Enter finishes this entry and advances to the next.
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
