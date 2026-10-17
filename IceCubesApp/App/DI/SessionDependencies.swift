import Env
import NeedleFoundation
import NetworkClient
import Timeline

/// What the session scope needs from its parent.
nonisolated protocol SessionDependency: Dependency {
  var userPreferences: UserPreferences { get }
  var hapticManager: HapticManager { get }
  var statusDataControllerProvider: StatusDataControllerProvider { get }
  var timelineContentFilter: TimelineContentFilter { get }
}

/// Session scope as a Needle child component; `client` is the forwarded runtime value.
nonisolated final class SessionComponent: Component<SessionDependency> {
  public let client: MastodonClient

  init(parent: Scope, client: MastodonClient) {
    self.client = client
    super.init(parent: parent)
  }

  public var currentAccount: CurrentAccount {
    let client = client
    return shared { MainActor.assumeIsolated { CurrentAccount(client: client) } }
  }
  public var currentInstance: CurrentInstance {
    let client = client
    return shared { MainActor.assumeIsolated { CurrentInstance(client: client) } }
  }
  public var streamWatcher: StreamWatcher {
    let client = client
    return shared { MainActor.assumeIsolated { StreamWatcher(client: client) } }
  }
  public var timelineComponent: TimelineComponent { TimelineComponent(parent: self) }
}

/// Thin owner the app and the environment hold; same shape as the manual variant.
@MainActor
final class SessionDependencies {
  let component: SessionComponent
  var client: MastodonClient { component.client }
  var currentAccount: CurrentAccount { component.currentAccount }
  var currentInstance: CurrentInstance { component.currentInstance }
  var streamWatcher: StreamWatcher { component.streamWatcher }

  init(component: SessionComponent) {
    self.component = component
  }

  /// Feature scope: a child component per timeline screen.
  func makeFeature() -> FeatureDependencies {
    FeatureDependencies(component: component.timelineComponent)
  }
}
