import AppAccount
import DesignSystem
import Env
import Foundation
import Models
import NetworkClient
import Timeline

/// Per-variant: obtains every app-scope service through this variant's own access path (Swinject container).
@MainActor
enum BenchResolve {
  static func resolveAll(_ deps: AppDependencies) {
    let c = deps.container
    BenchHooks.sink([
      c.resolve(Theme.self)!, c.resolve(UserPreferences.self)!, c.resolve(HapticManager.self)!,
      c.resolve(SoundEffectManager.self)!, c.resolve(AppAccountsManager.self)!,
      c.resolve(PushNotificationsService.self)!, c.resolve(QuickLook.self)!, c.resolve(ToastCenter.self)!,
      c.resolve(StatusEmbedCache.self)!, c.resolve(StatusDataControllerProvider.self)!,
      c.resolve(TimelineContentFilter.self)!,
    ])
  }

  /// This variant's scope mechanism, for the shared checks.
  static func scopeAccess(_ deps: AppDependencies) -> BenchScopeAccess {
    BenchScopeAccess(
      makeSession: { deps.makeSession(client: $0) },
      sessionObjects: { any in
        let s = any as! SessionDependencies
        return ["client": s.client, "currentAccount": s.currentAccount, "currentInstance": s.currentInstance, "streamWatcher": s.streamWatcher]
      },
      makeFeature: { ($0 as! SessionDependencies).makeFeature() },
      featureObjects: { ($0 as! FeatureDependencies).timelineScope.benchObjects },
      appObjectsUsing: { any in
        let s = any as! SessionDependencies
        _ = deps.statusDataControllerProvider.dataController(for: Status.placeholder(), client: s.client)
      })
  }
}
