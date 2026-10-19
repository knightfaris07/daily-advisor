# Daily Advisor

An iOS app that gives you a short daily coaching session with an AI advisor, grounded in today's business news.

## Features

- **Today:** a fresh question every day to start an honest session about a real situation you're in
- **Chat:** streaming conversation with Claude, with a typing indicator and message bubbles
- **News carousel:** headlines from BBC Business, Harvard Business Review, MIT Sloan and Fast Company, cached for offline use
- **History:** past sessions are saved on the device
- **Settings:** bring your own Anthropic API key, which is stored only on your phone

## Run it

1. Open the project in Xcode and run it on an iPhone simulator.
2. In the app, go to **Settings** and paste your Anthropic API key.
3. Start today's session.

## Project layout

| Folder | Contents |
| --- | --- |
| `Views/` | Today, Chat, History, Settings, splash screen and news carousel |
| `Services/` | Claude API client (streaming), RSS news fetcher, session storage, settings |
| `Models/` | Sessions, messages, news items, daily prompts |

## Built with

Swift · SwiftUI · Anthropic Claude API · vibe-coded with Claude Code
