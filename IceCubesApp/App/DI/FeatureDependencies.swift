import SafeDI
import Timeline

/// Feature scope: one timeline screen, instantiated under the session scope.
@Instantiable
@MainActor
public final class FeatureDependencies: Instantiable {
  @Instantiated public let timelineScope: TimelineFeatureScope

  public init(timelineScope: TimelineFeatureScope) {
    self.timelineScope = timelineScope
  }
}
