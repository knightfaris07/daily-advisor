import Foundation

struct NewsItem: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let url: String
    let source: String
    let publishedAt: Date

    init(title: String, description: String, url: String, source: String, publishedAt: Date) {
        self.title = title
        self.description = description
        self.url = url
        self.source = source
        self.publishedAt = publishedAt
    }
}
