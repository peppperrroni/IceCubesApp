import Account
import AppAccount
import DesignSystem
import Env
import NetworkClient
import StatusKit
import Swinject
import Timeline

/// Composition root: every app-lifetime service is registered once in a Swinject container.
/// This file is the source of truth for the benchmark manifest (apps/icecubes/manifest.json).
@MainActor
struct AppDependencies {
  let container = Container()

  let theme: Theme
  let userPreferences: UserPreferences
  let hapticManager: HapticManager
  let soundEffectManager: SoundEffectManager
  let appAccountsManager: AppAccountsManager
  let currentInstance: CurrentInstance
  let currentAccount: CurrentAccount
  let pushNotificationsService: PushNotificationsService
  let streamWatcher: StreamWatcher
  let quickLook: QuickLook
  let toastCenter: ToastCenter
  let statusEmbedCache: StatusEmbedCache
  let statusDataControllerProvider: StatusDataControllerProvider
  let timelineContentFilter: TimelineContentFilter

  init() {
    container.register(Theme.self) { _ in Theme() }.inObjectScope(.container)
    container.register(UserPreferences.self) { _ in UserPreferences() }.inObjectScope(.container)
    container.register(HapticManager.self) { r in
      HapticManager(userPreferences: r.resolve(UserPreferences.self)!)
    }.inObjectScope(.container)
    container.register(SoundEffectManager.self) { r in
      SoundEffectManager(userPreferences: r.resolve(UserPreferences.self)!)
    }.inObjectScope(.container)
    container.register(AppAccountsManager.self) { _ in AppAccountsManager() }.inObjectScope(.container)
    container.register(CurrentInstance.self) { _ in CurrentInstance() }.inObjectScope(.container)
    container.register(CurrentAccount.self) { _ in CurrentAccount() }.inObjectScope(.container)
    container.register(PushNotificationsService.self) { r in
      PushNotificationsService(userPreferences: r.resolve(UserPreferences.self)!)
    }.inObjectScope(.container)
    container.register(StreamWatcher.self) { _ in StreamWatcher() }.inObjectScope(.container)
    container.register(QuickLook.self) { _ in QuickLook() }.inObjectScope(.container)
    container.register(ToastCenter.self) { _ in ToastCenter() }.inObjectScope(.container)
    container.register(StatusEmbedCache.self) { _ in StatusEmbedCache() }.inObjectScope(.container)
    container.register(StatusDataControllerProvider.self) { _ in StatusDataControllerProvider() }
      .inObjectScope(.container)
    container.register(TimelineContentFilter.self) { _ in TimelineContentFilter() }.inObjectScope(.container)

    theme = container.resolve(Theme.self)!
    userPreferences = container.resolve(UserPreferences.self)!
    hapticManager = container.resolve(HapticManager.self)!
    soundEffectManager = container.resolve(SoundEffectManager.self)!
    appAccountsManager = container.resolve(AppAccountsManager.self)!
    currentInstance = container.resolve(CurrentInstance.self)!
    currentAccount = container.resolve(CurrentAccount.self)!
    pushNotificationsService = container.resolve(PushNotificationsService.self)!
    streamWatcher = container.resolve(StreamWatcher.self)!
    quickLook = container.resolve(QuickLook.self)!
    toastCenter = container.resolve(ToastCenter.self)!
    statusEmbedCache = container.resolve(StatusEmbedCache.self)!
    statusDataControllerProvider = container.resolve(StatusDataControllerProvider.self)!
    timelineContentFilter = container.resolve(TimelineContentFilter.self)!
    // Static helpers with no owner (Font, layoutPadding, DeepL key) read these.
    Theme.current = theme
    UserPreferences.current = userPreferences
  }
}
