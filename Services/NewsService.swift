import Foundation

@MainActor
final class NewsService: ObservableObject {
    @Published var items: [NewsItem] = []
    @Published var isLoading = false

    private struct Feed { let name: String; let url: String }

    private let feeds = [
        Feed(name: "HBR",         url: "https://feeds.hbr.org/harvardbusiness"),
        Feed(name: "Fast Company", url: "https://www.fastcompany.com/rss.xml"),
        Feed(name: "MIT Sloan",    url: "https://sloanreview.mit.edu/feed/"),
        Feed(name: "BBC Business", url: "https://feeds.bbci.co.uk/news/business/rss.xml"),
    ]

    // Load from cache if available and fresh; otherwise fetch
    func loadIfNeeded() {
        if let cache = loadCache(), Calendar.current.isDateInToday(cache.fetchedAt) {
            items = cache.items
            return
        }
        Task { await refresh() }
    }

    func refresh() async {
        isLoading = true

        // Fetch all four feeds concurrently on the cooperative pool
        async let f0 = Self.fetch(feeds[0])
        async let f1 = Self.fetch(feeds[1])
        async let f2 = Self.fetch(feeds[2])
        async let f3 = Self.fetch(feeds[3])

        // Take the top item from each feed (ensures variety), sort by date
        let best = await [f0, f1, f2, f3]
            .compactMap(\.first)
            .sorted { $0.publishedAt > $1.publishedAt }

        items = best
        isLoading = false
        if !best.isEmpty { saveCache(best) }
    }

    // nonisolated so URLSession runs on the cooperative thread pool, not main actor
    nonisolated private static func fetch(_ feed: Feed) async -> [NewsItem] {
        guard let url = URL(string: feed.url),
              let (data, _) = try? await URLSession.shared.data(from: url)
        else { return [] }
        return RSSParser.parse(data: data, sourceName: feed.name)
    }

    // MARK: - Cache

    private struct Cache: Codable {
        let items: [NewsItem]
        let fetchedAt: Date
    }

    private let cacheKey = "da_news_v1"

    private func saveCache(_ items: [NewsItem]) {
        if let data = try? JSONEncoder().encode(Cache(items: items, fetchedAt: .now)) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func loadCache() -> Cache? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode(Cache.self, from: data)
        else { return nil }
        return cache
    }
}
