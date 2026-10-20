import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: SessionStore
    @State private var showKey = false
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                List {
                    // API Key section
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Anthropic API Key")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                            Text("Required to use Claude. Stored in this device’s Keychain. Get your key at platform.anthropic.com.")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)

                            HStack {
                                Group {
                                    if showKey {
                                        TextField("sk-ant-api03-...", text: $settings.apiKey)
                                    } else {
                                        SecureField("sk-ant-api03-...", text: $settings.apiKey)
                                    }
                                }
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                                Button {
                                    showKey.toggle()
                                } label: {
                                    Image(systemName: showKey ? "eye.slash" : "eye")
                                        .foregroundStyle(Color.textSecondary)
                                        .frame(width: 30)
                                }
                            }
                            .padding(12)
                            .background(Color.appBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .listRowBackground(Color.appSurface)
                        .listRowSeparator(.hidden)

                        if !settings.apiKey.isEmpty {
                            Label("API key saved", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .listRowBackground(Color.appSurface)
                                .listRowSeparator(.hidden)
                        }

                        if let storageError = settings.apiKeyStorageError {
                            Label(storageError, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .listRowBackground(Color.appSurface)
                                .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text("API Configuration")
                            .foregroundStyle(Color.accent)
                            .font(.caption.weight(.semibold))
                    }

                    // Model info
                    Section {
                        infoRow(label: "Model", value: "claude-opus-4-8")
                        infoRow(label: "Thinking", value: "Adaptive (enabled)")
                        infoRow(label: "Max tokens", value: "1,500 per reply")
                    } header: {
                        Text("AI Configuration")
                            .foregroundStyle(Color.accent)
                            .font(.caption.weight(.semibold))
                    }

                    // Data
                    Section {
                        Button(role: .destructive) {
                            showClearAlert = true
                        } label: {
                            Label("Clear All Sessions", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                        .listRowBackground(Color.appSurface)
                    } header: {
                        Text("Data")
                            .foregroundStyle(Color.accent)
                            .font(.caption.weight(.semibold))
                    }

                    // About
                    Section {
                        infoRow(label: "App", value: "Daily Advisor")
                        infoRow(label: "Version", value: "1.0")
                    } header: {
                        Text("About")
                            .foregroundStyle(Color.accent)
                            .font(.caption.weight(.semibold))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .alert("Clear All Sessions?", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { store.clearAll() }
        } message: {
            Text("This will permanently delete all \(store.sessions.count) session\(store.sessions.count == 1 ? "" : "s"). This cannot be undone.")
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.appSurface)
    }
}
