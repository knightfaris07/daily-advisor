import Foundation

struct DailyPrompts {
    static let all: [String] = [
        "What leadership challenge have you been avoiding that deserves your attention today?",
        "If you could redesign your role to play to your greatest strengths, what would change?",
        "What feedback do you keep receiving but haven't fully acted on yet?",
        "Where are you playing it safe when your situation calls for bold action?",
        "What would you do differently in your career if failure wasn't a concern?",
        "Who on your team has potential you haven't fully invested in?",
        "What's one conversation you've been putting off that needs to happen this week?",
        "In what ways has your leadership style evolved over the past year?",
        "What does your team need from you right now that you haven't been giving them?",
        "Where do you feel most alive in your work, and how can you do more of that?",
        "What assumptions about your organization might be holding you back?",
        "How clear is your team on what success actually looks like for them?",
        "What would you do with your career if you knew you couldn't fail?",
        "Where are you confusing being busy with being effective?",
        "What relationships at work need more investment from you right now?",
        "How well do you really understand what motivates the people around you?",
        "What's the biggest decision you're wrestling with, and what's holding you back from deciding?",
        "In what areas are you the bottleneck on your team without fully realizing it?",
        "What would your team say is your greatest strength as a leader?",
        "What habits are quietly limiting your effectiveness as a leader?",
        "How aligned are your daily actions with your long-term career goals?",
        "What's one thing you could delegate that would free you for higher-value work?",
        "Where are you tolerating mediocrity — in yourself or in others?",
        "What's your vision for the kind of leader you want to become?",
        "How would your closest colleagues describe your presence in difficult conversations?",
        "What are you most proud of in the past month, and why does it matter?",
        "Where are you still seeking approval instead of leading with conviction?",
        "What's the next level of your career, and what do you need to develop to get there?",
        "How clearly can you articulate your personal leadership philosophy?",
        "What would a truly extraordinary version of your career look like?",
    ]

    static var today: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return all[(day - 1) % all.count]
    }
}
