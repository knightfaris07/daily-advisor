import Foundation

struct Session: Identifiable, Codable {
    var id = UUID()
    var title: String
    var messages: [Message] = []
    let createdAt: Date

    init(title: String, createdAt: Date = .now) {
        self.title = title
        self.createdAt = createdAt
    }

    var lastActivity: Date {
        messages.last?.timestamp ?? createdAt
    }

    var preview: String {
        if let last = messages.last(where: { $0.role == .assistant }) {
            return String(last.content.prefix(120))
        } else if let first = messages.first {
            return String(first.content.prefix(120))
        }
        return "No messages yet"
    }
}
