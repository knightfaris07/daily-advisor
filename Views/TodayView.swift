import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var settings: AppSettings
    @State private var activeSession: Session?
    @State private var pulseScale: CGFloat = 1
    @State private var pulseOpacity: Double = 0.45

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.title3)
                                .foregroundStyle(Color.textSecondary)
                            Text("Daily Session")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 8)

                        // News carousel
                        NewsCarousel()

                        // Date chip
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(Date.now, format: .dateTime.weekday(.wide))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.accent)
                                    .textCase(.uppercase)
                                    .tracking(0.8)
                                Text(Date.now, format: .dateTime.month(.wide).day().year())
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundStyle(Color.accent.opacity(0.6))
                        }
                        .padding(16)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Today's prompt
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Today's Question", systemImage: "sparkles")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.accent)
                                .textCase(.uppercase)
                                .tracking(0.8)

                            Text(DailyPrompts.today)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.white)
                                .lineSpacing(5)
                        }
                        .padding(20)
                        .background(Color.appSurface)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(Color.accent)
                                .frame(width: 3)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // CTA with heartbeat pulse
                        ZStack {
                            // Expanding pulse ring
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.accent.opacity(pulseOpacity))
                                .scaleEffect(pulseScale)
                                .onAppear {
                                    withAnimation(
                                        .easeOut(duration: 1.9)
                                        .repeatForever(autoreverses: false)
                                        .delay(0.4)
                                    ) {
                                        pulseScale   = 1.09
                                        pulseOpacity = 0
                                    }
                                }

                            Button {
                                let dateLabel = Date.now.formatted(.dateTime.month(.abbreviated).day())
                                activeSession = Session(title: "Session — \(dateLabel)")
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.headline)
                                    Text("Start Today's Session")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .padding(18)
                                .foregroundStyle(.black)
                                .background(Color.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        // Info / warning card
                        if settings.apiKey.isEmpty {
                            apiKeyWarning
                        } else {
                            tipCard
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $activeSession) { session in
            ChatView(session: session) { updated in
                if !updated.messages.isEmpty {
                    store.save(updated)
                }
            }
        }
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Color.accent)
                .padding(.top, 2)
            Text("Start by answering today's question honestly. The best sessions happen when you're specific about a real situation you're in right now.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var apiKeyWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .foregroundStyle(Color.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("API Key Required")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Add your Anthropic API key in Settings to activate your advisor.")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accent.opacity(0.35), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
