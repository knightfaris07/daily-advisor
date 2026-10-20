# Daily Advisor

An iOS app for a short daily coaching session with Claude, grounded in current business news.

## Features

- **Today:** a fresh question to start a session about a real situation
- **Chat:** streaming conversations with Claude
- **News:** business headlines cached for offline viewing
- **History:** previous sessions saved on the device
- **Settings:** use your own Anthropic API key, stored in the iOS Keychain

## Build and run

This repository currently contains Swift source files only; it does not include an Xcode project or workspace, so it cannot be opened and run as-is.

To try the source, create a new iOS App project in Xcode using SwiftUI, add the Swift files in this repository to the app target, then run it in an iPhone simulator. In the app, open **Settings** and enter an Anthropic API key to start a session.

## API key and data

The API key is stored in the iOS Keychain on the device and sent directly from the app to Anthropic for requests. This project does not proxy requests through a backend. API usage is billed to the Anthropic account associated with the key. Existing keys from earlier versions are moved from `UserDefaults` to the Keychain the first time this version launches.

Conversation history is stored locally on the device in `UserDefaults`.

## Project layout

| Folder | Contents |
| --- | --- |
| `Views/` | Today, Chat, History, Settings, splash screen and news carousel |
| `Services/` | Claude API client, RSS news fetcher, session storage and settings |
| `Models/` | Sessions, messages, news items and daily prompts |

## Built with

Swift · SwiftUI · Anthropic Claude API
