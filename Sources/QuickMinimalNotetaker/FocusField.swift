import Foundation

enum FocusField: Hashable {
    case page(UUID)
    case delete(UUID)
    case text(UUID)
    /// Nothing in particular selected. Holding real AppKit focus here (rather than
    /// focusedField being nil) is what lets the window still catch a bare Enter press.
    case root
}
