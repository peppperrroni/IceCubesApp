import Account
import AppAccount
import DesignSystem
import Env
import NetworkClient
import StatusKit
import Timeline

/// Composition root: every app-lifetime service is created exactly once here.
/// This file is the source of truth for the benchmark manifest (apps/icecubes/manifest.json).
@MainActor
struct AppDependencies {
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
    theme = Theme()
    userPreferences = UserPreferences()
    hapticManager = HapticManager(userPreferences: userPreferences)
    soundEffectManager = SoundEffectManager(userPreferences: userPreferences)
    appAccountsManager = AppAccountsManager()
    currentInstance = CurrentInstance()
    currentAccount = CurrentAccount()
    pushNotificationsService = PushNotificationsService(userPreferences: userPreferences)
    streamWatcher = StreamWatcher()
    quickLook = QuickLook()
    toastCenter = ToastCenter()
    statusEmbedCache = StatusEmbedCache()
    statusDataControllerProvider = StatusDataControllerProvider()
    timelineContentFilter = TimelineContentFilter()
    // Static helpers with no owner (Font, layoutPadding, DeepL key) read these.
    Theme.current = theme
    UserPreferences.current = userPreferences
  }
}
