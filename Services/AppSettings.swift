import Combine
import Foundation
import Security

private enum APIKeyStore {
    private static let account = "anthropic-api-key"
    private static let service = Bundle.main.bundleIdentifier ?? "DailyAdvisor"

    static func read() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.operationFailed(status) }
        guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidValue
        }
        return value
    }

    static func save(_ value: String) throws {
        let data = Data(value.utf8)
        let status = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.operationFailed(addStatus) }
        } else if status != errSecSuccess {
            throw KeychainError.operationFailed(status)
        }
    }

    static func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.operationFailed(status)
        }
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

private enum KeychainError: LocalizedError {
    case operationFailed(OSStatus)
    case invalidValue

    var errorDescription: String? {
        switch self {
        case .operationFailed(let status): return "Keychain operation failed (\(status))."
        case .invalidValue: return "Saved API key could not be read. Please enter it again."
        }
    }
}

final class AppSettings: ObservableObject {
    @Published var apiKey: String {
        didSet {
            do {
                if apiKey.isEmpty {
                    try APIKeyStore.delete()
                } else {
                    try APIKeyStore.save(apiKey)
                }
                apiKeyStorageError = nil
            } catch {
                apiKeyStorageError = error.localizedDescription
            }
        }
    }

    @Published private(set) var apiKeyStorageError: String?

    init() {
        let defaults = UserDefaults.standard
        let legacyAPIKey = defaults.string(forKey: "da_api_key")

        do {
            if let savedAPIKey = try APIKeyStore.read() {
                self.apiKey = savedAPIKey
                defaults.removeObject(forKey: "da_api_key")
            } else if let legacyAPIKey, !legacyAPIKey.isEmpty {
                try APIKeyStore.save(legacyAPIKey)
                self.apiKey = legacyAPIKey
                defaults.removeObject(forKey: "da_api_key")
            } else {
                self.apiKey = ""
            }
        } catch {
            self.apiKey = ""
            self.apiKeyStorageError = error.localizedDescription
        }
    }
}
