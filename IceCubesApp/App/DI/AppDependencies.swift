import Account
import AppAccount
import DesignSystem
import Env
import NetworkClient
import SafeDI
import StatusKit
import Timeline

// The Xcode plugin scans only the app target; the services live in local packages.
#SafeDIConfiguration(additionalDirectoriesToInclude: ["Packages"])

/// Composition root: SafeDI instantiates every service once and generates `init()`.
/// This file is the source of truth for the benchmark manifest (apps/icecubes/manifest.json).
@Instantiable(isRoot: true)
@MainActor
public final class AppDependencies: Instantiable {
  @Instantiated public let theme: Theme
  @Instantiated public let userPreferences: UserPreferences
  @Instantiated public let hapticManager: HapticManager
  @Instantiated public let soundEffectManager: SoundEffectManager
  @Instantiated public let appAccountsManager: AppAccountsManager
  @Instantiated public let currentInstance: CurrentInstance
  @Instantiated public let currentAccount: CurrentAccount
  @Instantiated public let pushNotificationsService: PushNotificationsService
  @Instantiated public let streamWatcher: StreamWatcher
  @Instantiated public let quickLook: QuickLook
  @Instantiated public let toastCenter: ToastCenter
  @Instantiated public let statusEmbedCache: StatusEmbedCache
  @Instantiated public let statusDataControllerProvider: StatusDataControllerProvider
  @Instantiated public let timelineContentFilter: TimelineContentFilter

  public init(
    theme: Theme,
    userPreferences: UserPreferences,
    hapticManager: HapticManager,
    soundEffectManager: SoundEffectManager,
    appAccountsManager: AppAccountsManager,
    currentInstance: CurrentInstance,
    currentAccount: CurrentAccount,
    pushNotificationsService: PushNotificationsService,
    streamWatcher: StreamWatcher,
    quickLook: QuickLook,
    toastCenter: ToastCenter,
    statusEmbedCache: StatusEmbedCache,
    statusDataControllerProvider: StatusDataControllerProvider,
    timelineContentFilter: TimelineContentFilter
  ) {
    self.theme = theme
    self.userPreferences = userPreferences
    self.hapticManager = hapticManager
    self.soundEffectManager = soundEffectManager
    self.appAccountsManager = appAccountsManager
    self.currentInstance = currentInstance
    self.currentAccount = currentAccount
    self.pushNotificationsService = pushNotificationsService
    self.streamWatcher = streamWatcher
    self.quickLook = quickLook
    self.toastCenter = toastCenter
    self.statusEmbedCache = statusEmbedCache
    self.statusDataControllerProvider = statusDataControllerProvider
    self.timelineContentFilter = timelineContentFilter
  }
}
