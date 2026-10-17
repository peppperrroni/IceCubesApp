import NetworkClient
import SwiftUI

@MainActor
extension View {
  public func withPreviewsEnv() -> some View {
    let userPreferences = UserPreferences()
    return environment(RouterPath())
      .environment(MastodonClient(server: ""))
      .environment(CurrentAccount(client: MastodonClient(server: "")))
      .environment(userPreferences)
      .environment(CurrentInstance(client: MastodonClient(server: "")))
      .environment(PushNotificationsService(userPreferences: userPreferences))
      .environment(QuickLook())
      .environment(HapticManager(userPreferences: userPreferences))
      .environment(SoundEffectManager(userPreferences: userPreferences))
      .environment(StatusEmbedCache())
      .environment(StatusDataControllerProvider())
      .environment(ToastCenter())
  }
}
