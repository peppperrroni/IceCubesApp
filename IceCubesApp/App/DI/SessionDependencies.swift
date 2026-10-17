import Env
import NetworkClient
import SafeDI

/// Session scope as a SafeDI sub-tree rooted at the forwarded client.
@Instantiable
@MainActor
public final class SessionDependencies: Instantiable {
  @Forwarded public let client: MastodonClient
  @Instantiated public let currentAccount: CurrentAccount
  @Instantiated public let currentInstance: CurrentInstance
  @Instantiated public let streamWatcher: StreamWatcher
  @Instantiated private let featureInstantiator: Instantiator<FeatureDependencies>

  public init(
    client: MastodonClient,
    currentAccount: CurrentAccount,
    currentInstance: CurrentInstance,
    streamWatcher: StreamWatcher,
    featureInstantiator: Instantiator<FeatureDependencies>
  ) {
    self.client = client
    self.currentAccount = currentAccount
    self.currentInstance = currentInstance
    self.streamWatcher = streamWatcher
    self.featureInstantiator = featureInstantiator
  }

  /// Feature scope: one per timeline screen.
  func makeFeature() -> FeatureDependencies {
    featureInstantiator.instantiate()
  }
}
