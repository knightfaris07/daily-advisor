import SwiftUI

struct NewsCarousel: View {
    @StateObject private var news = NewsService()
    @State private var page = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            if news.isLoading && news.items.isEmpty {
                placeholder
            } else if news.items.isEmpty {
                emptyState
            } else {
                TabView(selection: $page) {
                    ForEach(Array(news.items.enumerated()), id: \.element.id) { i, item in
                        NewsSlide(item: item)
                            .tag(i)
                            .padding(.horizontal, 1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 164)

                // Page indicators
                HStack(spacing: 5) {
                    ForEach(0..<news.items.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.accent : Color.textSecondary.opacity(0.3))
                            .frame(width: i == page ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { news.loadIfNeeded() }
    }

    // MARK: - Subviews

    private var sectionHeader: some View {
        HStack {
            Label("Today's Headlines", systemImage: "newspaper.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accent)
                .textCase(.uppercase)
                .tracking(0.8)
            Spacer()
            Button {
                Task { await news.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(news.isLoading ? Color.accent : Color.textSecondary)
                    .rotationEffect(.degrees(news.isLoading ? 360 : 0))
                    .animation(
                        news.isLoading
                            ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                            : .default,
                        value: news.isLoading
                    )
            }
            .disabled(news.isLoading)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.appSurface)
            .frame(height: 164)
            .overlay {
                HStack(spacing: 10) {
                    ProgressView().tint(Color.accent)
                    Text("Loading headlines…")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
    }

    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.appSurface)
            .frame(height: 164)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "newspaper")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.textSecondary)
                    Text("Couldn't load headlines")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textSecondary)
                    Button("Try Again") { Task { await news.refresh() } }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accent)
                }
            }
    }
}

// MARK: - Individual slide

struct NewsSlide: View {
    let item: NewsItem

    var body: some View {
        Button {
            guard let url = URL(string: item.url) else { return }
            UIApplication.shared.open(url)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Source + age
                HStack(alignment: .center) {
                    Text(item.source.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(Color.accent)
                    Spacer()
                    Text(item.publishedAt, format: .relative(presentation: .named))
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.bottom, 10)

                // Headline
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2.5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                // Footer
                HStack {
                    if !item.description.isEmpty {
                        Text(item.description)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    HStack(spacing: 3) {
                        Text("Read")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(Color.accent.opacity(0.85))
                }
                .padding(.top, 8)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
