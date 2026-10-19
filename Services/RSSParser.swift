import Foundation

final class RSSParser: NSObject, XMLParserDelegate {
    private(set) var items: [NewsItem] = []
    private let sourceName: String

    private var isInItem = false
    private var currentElement = ""
    private var currentText = ""
    private var parsed = ParsedItem()

    private struct ParsedItem {
        var title = ""
        var description = ""
        var link = ""
        var pubDate = ""
    }

    private init(sourceName: String) {
        self.sourceName = sourceName
    }

    static func parse(data: Data, sourceName: String) -> [NewsItem] {
        let rss = RSSParser(sourceName: sourceName)
        let parser = XMLParser(data: data)
        parser.delegate = rss
        parser.parse()
        return rss.items
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attrs: [String: String] = [:]
    ) {
        currentElement = elementName.lowercased()
        currentText = ""

        if currentElement == "item" || currentElement == "entry" {
            isInItem = true
            parsed = ParsedItem()
        }
        // Atom feeds use <link href="…"/> (no text content)
        if isInItem && currentElement == "link", let href = attrs["href"], !href.isEmpty {
            parsed.link = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, foundCDATA block: Data) {
        if let text = String(data: block, encoding: .utf8) {
            currentText += text
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard isInItem else { return }
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName.lowercased() {
        case "title":
            parsed.title = stripHTML(text)
        case "description", "summary", "content", "content:encoded":
            if parsed.description.isEmpty {
                parsed.description = String(stripHTML(text).prefix(200))
            }
        case "link":
            if parsed.link.isEmpty { parsed.link = text }
        case "pubdate", "published", "updated", "dc:date":
            if parsed.pubDate.isEmpty { parsed.pubDate = text }
        case "item", "entry":
            if !parsed.title.isEmpty {
                items.append(NewsItem(
                    title: parsed.title,
                    description: parsed.description,
                    url: parsed.link,
                    source: sourceName,
                    publishedAt: parseDate(parsed.pubDate) ?? .now
                ))
            }
            isInItem = false
        default:
            break
        }
    }

    // MARK: - Helpers

    private func stripHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseDate(_ s: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
        ]
        for fmt in formats {
            formatter.dateFormat = fmt
            if let date = formatter.date(from: s) { return date }
        }
        return nil
    }
}
