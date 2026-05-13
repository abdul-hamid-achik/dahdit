import Foundation
import Security

actor KeychainTokenStore {
    private let service = "dev.dahdit.app"
    private var cachedAccessToken: String?
    private var cachedRefreshToken: String?

    func access() -> String? {
        if let cachedAccessToken { return cachedAccessToken }
        cachedAccessToken = read(account: "dahdit.accessToken")
        return cachedAccessToken
    }

    func refresh() -> String? {
        if let cachedRefreshToken { return cachedRefreshToken }
        cachedRefreshToken = read(account: "dahdit.refreshToken")
        return cachedRefreshToken
    }

    func set(accessToken: String, refreshToken: String) {
        cachedAccessToken = accessToken
        cachedRefreshToken = refreshToken
        write(accessToken, account: "dahdit.accessToken")
        write(refreshToken, account: "dahdit.refreshToken")
    }

    func clear() {
        cachedAccessToken = nil
        cachedRefreshToken = nil
        delete(account: "dahdit.accessToken")
        delete(account: "dahdit.refreshToken")
    }

    private func read(account: String) -> String? {
        var query = keyQuery(account: account)
        query.merge([
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]) { _, new in new }

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
#if DEBUG
            return UserDefaults.standard.string(forKey: fallbackKey(account: account))
#else
            return nil
#endif
        }
        return String(data: data, encoding: .utf8)
    }

    private func write(_ value: String, account: String) {
        let data = Data(value.utf8)
        var addQuery = keyQuery(account: account)
        addQuery.merge([
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]) { _, new in new }

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        let finalStatus: OSStatus
        if status == errSecDuplicateItem {
            finalStatus = SecItemUpdate(
                keyQuery(account: account) as CFDictionary,
                [kSecValueData as String: data] as CFDictionary
            )
        } else {
            finalStatus = status
        }

#if DEBUG
        if finalStatus == errSecSuccess {
            UserDefaults.standard.removeObject(forKey: fallbackKey(account: account))
        } else {
            UserDefaults.standard.set(value, forKey: fallbackKey(account: account))
        }
#endif
    }

    private func delete(account: String) {
        SecItemDelete(keyQuery(account: account) as CFDictionary)
#if DEBUG
        UserDefaults.standard.removeObject(forKey: fallbackKey(account: account))
#endif
    }

    private func keyQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

#if DEBUG
    private func fallbackKey(account: String) -> String {
        "\(service).debugFallback.\(account)"
    }
#endif
}
