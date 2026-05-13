import DahditAudio
import DahditGraphQL
import Foundation
import Observation

@Observable
final class AppEnvironment {
    let api: DahditAPI
    let audio: MorseAudioPlayer
    @MainActor let haptics: MorseHapticPlayer
    let tokenStore: KeychainTokenStore
    let tokenRefresher: TokenRefreshCoordinator

    init(
        api: DahditAPI,
        audio: MorseAudioPlayer,
        haptics: MorseHapticPlayer,
        tokenStore: KeychainTokenStore,
        tokenRefresher: TokenRefreshCoordinator
    ) {
        self.api = api
        self.audio = audio
        self.haptics = haptics
        self.tokenStore = tokenStore
        self.tokenRefresher = tokenRefresher
    }

    @MainActor
    static var live: AppEnvironment {
        let tokenStore = KeychainTokenStore()
        let endpoint = URL(string: Secrets.graphQLEndpoint)!
        let tokenRefresher = TokenRefreshCoordinator(endpoint: endpoint, tokenStore: tokenStore)
        return AppEnvironment(
            api: DahditAPI(
                endpoint: endpoint,
                tokenProvider: { await tokenStore.access() },
                tokenRefreshHandler: { await tokenRefresher.refresh() }
            ),
            audio: MorseAudioPlayer(),
            haptics: MorseHapticPlayer(),
            tokenStore: tokenStore,
            tokenRefresher: tokenRefresher
        )
    }
}
