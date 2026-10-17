import Env
import Foundation

/// Feature scope of one timeline screen: owns the view model and its collaborators.
/// Public so a composition root outside the package can create and hold it without
/// widening TimelineViewModel's API.
@MainActor
public final class TimelineFeatureScope {
  let viewModel: TimelineViewModel

  public init(
    userPreferences: UserPreferences,
    statusDataControllerProvider: StatusDataControllerProvider,
    watcher: StreamWatcher,
    timelineContentFilter: TimelineContentFilter,
    hapticManager: HapticManager
  ) {
    viewModel = TimelineViewModel(
      userPreferences: userPreferences, statusDataControllerProvider: statusDataControllerProvider,
      watcher: watcher, timelineContentFilter: timelineContentFilter, hapticManager: hapticManager)
  }

  /// Benchmark access to the scoped objects by name, for identity and lifetime checks.
  public var benchObjects: [String: AnyObject] {
    ["timelineViewModel": viewModel, "datasource": viewModel.datasource, "unreadObserver": viewModel.pendingStatusesObserver]
  }
}
