import Env
import NetworkClient

/// Session scope: owns everything bound to the current client. Replaced when the client changes.
@MainActor
final class SessionDependencies {
  let app: AppDependencies
  let client: MastodonClient
  let currentAccount: CurrentAccount
  let currentInstance: CurrentInstance
  let streamWatcher: StreamWatcher

  init(app: AppDependencies, client: MastodonClient) {
    self.app = app
    self.client = client
    currentAccount = CurrentAccount(client: client)
    currentInstance = CurrentInstance(client: client)
    streamWatcher = StreamWatcher(client: client)
    app.userPreferences.setClient(client: client)  // app-scope object, per-server preferences
  }

  /// Feature scope: one per timeline screen.
  func makeFeature() -> FeatureDependencies {
    FeatureDependencies(session: self)
  }
}
