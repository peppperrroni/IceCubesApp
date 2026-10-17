import Foundation

/// Per-variant: obtains every service through this variant's own access path.
@MainActor
enum BenchResolve {
  static func resolveAll(_ deps: AppDependencies) {
    BenchHooks.sink([
      deps.theme, deps.userPreferences, deps.hapticManager, deps.soundEffectManager,
      deps.appAccountsManager, deps.pushNotificationsService, deps.quickLook, deps.toastCenter,
      deps.statusEmbedCache, deps.statusDataControllerProvider, deps.timelineContentFilter,
    ])
  }
}
