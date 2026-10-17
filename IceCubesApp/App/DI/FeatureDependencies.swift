import Env
import Swinject
import Timeline

/// Feature scope as a Swinject child container of the session container.
@MainActor
final class FeatureDependencies {
  let container: Container
  let timelineScope: TimelineFeatureScope

  init(session: SessionDependencies) {
    container = Container(parent: session.container)
    container.register(TimelineFeatureScope.self) { r in
      TimelineFeatureScope(
        userPreferences: r.resolve(UserPreferences.self)!,
        statusDataControllerProvider: r.resolve(StatusDataControllerProvider.self)!,
        watcher: r.resolve(StreamWatcher.self)!,
        timelineContentFilter: r.resolve(TimelineContentFilter.self)!,
        hapticManager: r.resolve(HapticManager.self)!)
    }.inObjectScope(.container)
    timelineScope = container.resolve(TimelineFeatureScope.self)!
  }
}
