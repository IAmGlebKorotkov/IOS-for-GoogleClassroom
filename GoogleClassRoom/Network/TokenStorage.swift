import Foundation
import Security

final class TokenStorage {
    static let shared = TokenStorage()
    private init() {}

    private let accessKey = "com.googleclassroom.accessToken"
    private let refreshKey = "com.googleclassroom.refreshToken"

    var accessToken: String? {
        get { load(key: accessKey) }
        set {
            if let value = newValue { save(key: accessKey, value: value) }
            else { delete(key: accessKey) }
        }
    }

    var refreshToken: String? {
        get { load(key: refreshKey) }
        set {
            if let value = newValue { save(key: refreshKey, value: value) }
            else { delete(key: refreshKey) }
        }
    }

    func clearAll() {
        delete(key: accessKey)
        delete(key: refreshKey)
    }

    private func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
