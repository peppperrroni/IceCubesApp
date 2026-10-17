import Env
import NeedleFoundation
import Timeline

/// What the feature scope needs from its parents (session and app).
nonisolated protocol TimelineDependency: Dependency {
  var userPreferences: UserPreferences { get }
  var hapticManager: HapticManager { get }
  var statusDataControllerProvider: StatusDataControllerProvider { get }
  var timelineContentFilter: TimelineContentFilter { get }
  var streamWatcher: StreamWatcher { get }
}

/// Feature scope as a Needle child component of the session component.
nonisolated final class TimelineComponent: Component<TimelineDependency> {
  public var timelineScope: TimelineFeatureScope {
    // `dependency` is implicitly unwrapped in NeedleFoundation; read the members here, outside the isolated closure
    let userPreferences = dependency.userPreferences, provider = dependency.statusDataControllerProvider
    let watcher = dependency.streamWatcher, filter = dependency.timelineContentFilter, haptics = dependency.hapticManager
    return shared {
      MainActor.assumeIsolated {
        TimelineFeatureScope(
          userPreferences: userPreferences, statusDataControllerProvider: provider,
          watcher: watcher, timelineContentFilter: filter, hapticManager: haptics)
      }
    }
  }
}

@MainActor
final class FeatureDependencies {
  let component: TimelineComponent
  var timelineScope: TimelineFeatureScope { component.timelineScope }

  init(component: TimelineComponent) {
    self.component = component
  }
}
