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

/// Composition root: SafeDI instantiates every app-scope service once and generates `init()`.
/// Session scopes are created through an Instantiator that forwards the client.
/// This file is the source of truth for the benchmark manifest (apps/icecubes/manifest.json).
@Instantiable(isRoot: true)
@MainActor
public final class AppDependencies: Instantiable {
  @Instantiated public let theme: Theme
  @Instantiated public let userPreferences: UserPreferences
  @Instantiated public let hapticManager: HapticManager
  @Instantiated public let soundEffectManager: SoundEffectManager
  @Instantiated public let appAccountsManager: AppAccountsManager
  @Instantiated public let pushNotificationsService: PushNotificationsService
  @Instantiated public let quickLook: QuickLook
  @Instantiated public let toastCenter: ToastCenter
  @Instantiated public let statusEmbedCache: StatusEmbedCache
  @Instantiated public let statusDataControllerProvider: StatusDataControllerProvider
  @Instantiated public let timelineContentFilter: TimelineContentFilter
  @Instantiated private let sessionInstantiator: Instantiator<SessionDependencies>

  public init(
    theme: Theme,
    userPreferences: UserPreferences,
    hapticManager: HapticManager,
    soundEffectManager: SoundEffectManager,
    appAccountsManager: AppAccountsManager,
    pushNotificationsService: PushNotificationsService,
    quickLook: QuickLook,
    toastCenter: ToastCenter,
    statusEmbedCache: StatusEmbedCache,
    statusDataControllerProvider: StatusDataControllerProvider,
    timelineContentFilter: TimelineContentFilter,
    sessionInstantiator: Instantiator<SessionDependencies>
  ) {
    self.theme = theme
    self.userPreferences = userPreferences
    self.hapticManager = hapticManager
    self.soundEffectManager = soundEffectManager
    self.appAccountsManager = appAccountsManager
    self.pushNotificationsService = pushNotificationsService
    self.quickLook = quickLook
    self.toastCenter = toastCenter
    self.statusEmbedCache = statusEmbedCache
    self.statusDataControllerProvider = statusDataControllerProvider
    self.timelineContentFilter = timelineContentFilter
    self.sessionInstantiator = sessionInstantiator
  }

  /// Session scope: forwards the client into a SafeDI sub-tree.
  func makeSession(client: MastodonClient) -> SessionDependencies {
    userPreferences.setClient(client: client)  // app-scope object, per-server preferences
    return sessionInstantiator.instantiate(client)
  }
}
