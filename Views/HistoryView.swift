import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: SessionStore
    @State private var selectedSession: Session?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if store.sessions.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.sessions) { session in
                            SessionRow(session: session)
                                .listRowBackground(Color.appSurface.clipShape(RoundedRectangle(cornerRadius: 12)))
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                .onTapGesture { selectedSession = session }
                        }
                        .onDelete { store.delete(at: $0) }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Sessions")
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .fullScreenCover(item: $selectedSession) { session in
            ChatView(session: session) { updated in
                store.save(updated)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 52))
                .foregroundStyle(Color.textSecondary)
            Text("No sessions yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("Start a session from the Today tab\nand it will appear here.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct SessionRow: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text(session.lastActivity, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Text(session.preview)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)
                .lineSpacing(2)

            HStack(spacing: 4) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.caption2)
                Text("\(session.messages.count) message\(session.messages.count == 1 ? "" : "s")")
                    .font(.caption2)
            }
            .foregroundStyle(Color.accent.opacity(0.7))
            .padding(.top, 2)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}
