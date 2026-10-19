import Foundation

class AppSettings: ObservableObject {
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "da_api_key") }
    }

    init() {
        self.apiKey = UserDefaults.standard.string(forKey: "da_api_key") ?? ""
    }
}
