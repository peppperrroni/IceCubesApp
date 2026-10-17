import AppAccount
import DesignSystem
import Env
import Foundation
import Timeline

/// Per-variant: obtains every service through this variant's own access path (Swinject container).
@MainActor
enum BenchResolve {
  static func resolveAll(_ deps: AppDependencies) {
    let c = deps.container
    BenchHooks.sink([
      c.resolve(Theme.self)!, c.resolve(UserPreferences.self)!, c.resolve(HapticManager.self)!,
      c.resolve(SoundEffectManager.self)!, c.resolve(AppAccountsManager.self)!,
      c.resolve(CurrentInstance.self)!, c.resolve(CurrentAccount.self)!,
      c.resolve(PushNotificationsService.self)!, c.resolve(StreamWatcher.self)!,
      c.resolve(QuickLook.self)!, c.resolve(ToastCenter.self)!, c.resolve(StatusEmbedCache.self)!,
      c.resolve(StatusDataControllerProvider.self)!, c.resolve(TimelineContentFilter.self)!,
    ])
  }
}
