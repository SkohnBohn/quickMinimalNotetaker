import Foundation

struct Entry: Identifiable, Codable, Equatable {
    let id: UUID
    var page: String
    var text: String

    init(id: UUID = UUID(), page: String = "", text: String = "") {
        self.id = id
        self.page = page
        self.text = text
    }
}
