import DahditGraphQL
import Foundation

actor TokenRefreshCoordinator {
    private let tokenStore: KeychainTokenStore
    private let refreshAPI: DahditAPI
    private var inFlight: Task<Bool, Never>?

    init(endpoint: URL, tokenStore: KeychainTokenStore) {
        self.tokenStore = tokenStore
        refreshAPI = DahditAPI(endpoint: endpoint, tokenProvider: { nil })
    }

    func refresh() async -> Bool {
        if let inFlight {
            return await inFlight.value
        }

        let task = Task { [tokenStore, refreshAPI] in
            guard let refreshToken = await tokenStore.refresh() else {
                return false
            }

            do {
                let payload = try await refreshAPI.refreshToken(refreshToken)
                await tokenStore.set(
                    accessToken: payload.accessToken,
                    refreshToken: payload.refreshToken
                )
                return true
            } catch {
                await tokenStore.clear()
                return false
            }
        }

        inFlight = task
        let result = await task.value
        inFlight = nil
        return result
    }
}
