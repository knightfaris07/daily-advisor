import SwiftUI

@main
struct DailyAdvisorApp: App {
    @StateObject private var store    = SessionStore()
    @StateObject private var settings = AppSettings()
    @State private var splashDone     = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(store)
                    .environmentObject(settings)

                if !splashDone {
                    SplashView { splashDone = true }
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
