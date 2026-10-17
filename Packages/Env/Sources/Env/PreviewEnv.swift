import NetworkClient
import SwiftUI

@MainActor
extension View {
  public func withPreviewsEnv() -> some View {
    let userPreferences = UserPreferences()
    return environment(RouterPath())
      .environment(MastodonClient(server: ""))
      .environment(CurrentAccount())
      .environment(userPreferences)
      .environment(CurrentInstance())
      .environment(PushNotificationsService(userPreferences: userPreferences))
      .environment(QuickLook())
      .environment(HapticManager(userPreferences: userPreferences))
      .environment(SoundEffectManager(userPreferences: userPreferences))
      .environment(StatusEmbedCache())
      .environment(StatusDataControllerProvider())
      .environment(ToastCenter())
  }
}
