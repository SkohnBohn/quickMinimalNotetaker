import Foundation

enum FocusField: Hashable {
    case page(UUID)
    case delete(UUID)
    case text(UUID)
}
