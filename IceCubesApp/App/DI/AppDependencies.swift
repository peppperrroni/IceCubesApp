import Account
import AppAccount
import DesignSystem
import Env
import NeedleFoundation
import NetworkClient
import StatusKit
import Timeline

/// Composition root as a Needle bootstrap component: one scope, one `shared` instance per service.
/// This file is the source of truth for the benchmark manifest (apps/icecubes/manifest.json).
/// NeedleFoundation is Swift-5-mode without actor support, so MainActor types are built inside
/// `MainActor.assumeIsolated`; the root is created on the main thread by IceCubesApp.
nonisolated final class AppDependencies: BootstrapComponent {
  public var theme: Theme { shared { MainActor.assumeIsolated { Theme() } } }
  public var userPreferences: UserPreferences { shared { MainActor.assumeIsolated { UserPreferences() } } }
  public var hapticManager: HapticManager {
    let userPreferences = userPreferences
    return shared { MainActor.assumeIsolated { HapticManager(userPreferences: userPreferences) } }
  }
  public var soundEffectManager: SoundEffectManager {
    let userPreferences = userPreferences
    return shared { MainActor.assumeIsolated { SoundEffectManager(userPreferences: userPreferences) } }
  }
  public var appAccountsManager: AppAccountsManager { shared { MainActor.assumeIsolated { AppAccountsManager() } } }
  public var currentInstance: CurrentInstance { shared { MainActor.assumeIsolated { CurrentInstance() } } }
  public var currentAccount: CurrentAccount { shared { MainActor.assumeIsolated { CurrentAccount() } } }
  public var pushNotificationsService: PushNotificationsService {
    let userPreferences = userPreferences
    return shared { MainActor.assumeIsolated { PushNotificationsService(userPreferences: userPreferences) } }
  }
  public var streamWatcher: StreamWatcher { shared { MainActor.assumeIsolated { StreamWatcher() } } }
  public var quickLook: QuickLook { shared { MainActor.assumeIsolated { QuickLook() } } }
  public var toastCenter: ToastCenter { shared { MainActor.assumeIsolated { ToastCenter() } } }
  public var statusEmbedCache: StatusEmbedCache { shared { MainActor.assumeIsolated { StatusEmbedCache() } } }
  public var statusDataControllerProvider: StatusDataControllerProvider {
    shared { MainActor.assumeIsolated { StatusDataControllerProvider() } }
  }
  public var timelineContentFilter: TimelineContentFilter {
    shared { MainActor.assumeIsolated { TimelineContentFilter() } }
  }
}
