import Foundation
import Models
import NetworkClient

/// Per-variant: obtains every app-scope service through this variant's own access path (Needle `shared` lookups).
@MainActor
enum BenchResolve {
  static func resolveAll(_ deps: AppDependencies) {
    BenchHooks.sink([
      deps.theme, deps.userPreferences, deps.hapticManager, deps.soundEffectManager,
      deps.appAccountsManager, deps.pushNotificationsService, deps.quickLook, deps.toastCenter,
      deps.statusEmbedCache, deps.statusDataControllerProvider, deps.timelineContentFilter,
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
