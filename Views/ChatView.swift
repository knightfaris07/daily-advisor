import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: AppSettings

    @State private var session: Session
    @State private var inputText = ""
    @State private var isStreaming = false
    @State private var streamingText = ""
    @State private var errorMessage: String?
    @State private var cancelStream: (() -> Void)?

    private let claude = ClaudeService()
    let onDismiss: (Session) -> Void

    init(session: Session, onDismiss: @escaping (Session) -> Void) {
        self._session = State(initialValue: session)
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    messageList
                    Divider().background(Color.appSurface)
                    inputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { handleDismiss() }
                        .foregroundStyle(Color.accent)
                        .fontWeight(.medium)
                }
                ToolbarItem(placement: .principal) {
                    Text(session.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") { errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    if session.messages.isEmpty {
                        welcomeCard
                            .padding(.top, 16)
                    }

                    ForEach(session.messages) { msg in
                        MessageBubble(message: msg)
                    }

                    if isStreaming {
                        if streamingText.isEmpty {
                            TypingIndicator()
                                .id("typing")
                        } else {
                            MessageBubble(
                                message: Message(role: .assistant, content: streamingText)
                            )
                            .id("streaming")
                        }
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .onChange(of: session.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom") }
            }
            .onChange(of: streamingText) { _, _ in
                proxy.scrollTo("bottom")
            }
            .onChange(of: isStreaming) { _, streaming in
                if streaming { withAnimation { proxy.scrollTo("bottom") } }
            }
        }
    }

    // MARK: - Welcome card

    private var welcomeCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 42))
                .foregroundStyle(Color.accent)

            Text("Your consulting session starts here.")
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Share what's on your mind — a challenge you're facing, a decision you're wrestling with, or simply what you want to work on today.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                "",
                text: $inputText,
                prompt: Text("What's on your mind?").foregroundStyle(Color.textSecondary),
                axis: .vertical
            )
            .lineLimit(1...6)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .foregroundStyle(.white)
            .onSubmit { if canSend { send() } }

            Button {
                if isStreaming {
                    cancelStream?()
                    finaliseStreaming()
                } else {
                    send()
                }
            } label: {
                Image(systemName: isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(isStreaming ? Color.accent : (canSend ? Color.accent : Color.textSecondary))
            }
            .disabled(!canSend && !isStreaming)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.appBackground)
    }

    // MARK: - Actions

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isStreaming
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        session.messages.append(Message(role: .user, content: text))
        isStreaming = true
        streamingText = ""
        errorMessage = nil

        cancelStream = claude.sendMessage(
            messages: session.messages,
            apiKey: settings.apiKey,
            onToken: { token in
                streamingText += token
            },
            onComplete: { error in
                if let error {
                    errorMessage = error.localizedDescription
                    isStreaming = false
                    streamingText = ""
                } else {
                    finaliseStreaming()
                }
            }
        )
    }

    private func finaliseStreaming() {
        let text = streamingText
        if !text.isEmpty {
            session.messages.append(Message(role: .assistant, content: text))
        }
        streamingText = ""
        isStreaming = false
        cancelStream = nil
    }

    private func handleDismiss() {
        cancelStream?()
        cancelStream = nil
        if !streamingText.isEmpty {
            session.messages.append(Message(role: .assistant, content: streamingText))
            streamingText = ""
        }
        isStreaming = false
        onDismiss(session)
        dismiss()
    }
}
