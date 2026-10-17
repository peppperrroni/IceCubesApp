import Env
import NetworkClient
import Swinject

/// Session scope as a Swinject child container of the app container; `.container` scope ties
/// instances to this container's lifetime.
@MainActor
final class SessionDependencies {
  let app: AppDependencies
  let container: Container
  let client: MastodonClient
  let currentAccount: CurrentAccount
  let currentInstance: CurrentInstance
  let streamWatcher: StreamWatcher

  init(app: AppDependencies, client: MastodonClient) {
    self.app = app
    self.client = client
    container = Container(parent: app.container)
    container.register(MastodonClient.self) { _ in client }.inObjectScope(.container)
    container.register(CurrentAccount.self) { r in CurrentAccount(client: r.resolve(MastodonClient.self)!) }.inObjectScope(.container)
    container.register(CurrentInstance.self) { r in CurrentInstance(client: r.resolve(MastodonClient.self)!) }.inObjectScope(.container)
    container.register(StreamWatcher.self) { r in StreamWatcher(client: r.resolve(MastodonClient.self)!) }.inObjectScope(.container)
    currentAccount = container.resolve(CurrentAccount.self)!
    currentInstance = container.resolve(CurrentInstance.self)!
    streamWatcher = container.resolve(StreamWatcher.self)!
    app.userPreferences.setClient(client: client)  // app-scope object, per-server preferences
  }

  /// Feature scope: a child container per timeline screen.
  func makeFeature() -> FeatureDependencies {
    FeatureDependencies(session: self)
  }
}
