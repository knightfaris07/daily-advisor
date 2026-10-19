import SwiftUI

struct MessageBubble: View {
    let message: Message

    @State private var appeared = false

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 56) }

            if !isUser {
                Circle()
                    .fill(Color.appSurfaceHigh)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.accent)
                    }
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.5)
            }

            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(isUser ? Color.accent : Color.appSurface)
                .foregroundStyle(isUser ? .black : .white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .font(.body)
                .lineSpacing(3)
                .textSelection(.enabled)
                // Pop in from the relevant side
                .scaleEffect(appeared ? 1 : 0.82, anchor: isUser ? .bottomTrailing : .bottomLeading)
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : (isUser ? 12 : -12))

            if !isUser { Spacer(minLength: 56) }
        }
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }
}
