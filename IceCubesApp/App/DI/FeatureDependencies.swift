import Timeline

/// Feature scope: one timeline screen. Lives exactly as long as the view that owns it.
@MainActor
final class FeatureDependencies {
  let timelineScope: TimelineFeatureScope

  init(session: SessionDependencies) {
    timelineScope = TimelineFeatureScope(
      userPreferences: session.app.userPreferences,
      statusDataControllerProvider: session.app.statusDataControllerProvider,
      watcher: session.streamWatcher,
      timelineContentFilter: session.app.timelineContentFilter,
      hapticManager: session.app.hapticManager)
  }
}
