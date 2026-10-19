import Foundation

struct Message: Identifiable, Codable, Equatable {
    var id = UUID()
    let role: Role
    var content: String
    let timestamp: Date

    enum Role: String, Codable {
        case user, assistant
    }

    init(role: Role, content: String, timestamp: Date = .now) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
