import SwiftUI

/// Reports each entry row's frame (in the list's own coordinate space) up to
/// ContentView, so a drag in progress can tell which row it's currently over.
struct RowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
