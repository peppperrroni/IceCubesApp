import Env
import Foundation
import SafeDI

/// Feature scope of one timeline screen: owns the view model and its collaborators.
/// SafeDI instantiates it from the session scope; the received properties are stored because
/// SafeDI requires decorated dependencies to be immutable stored properties.
@Instantiable
@MainActor
public final class TimelineFeatureScope: Instantiable {
  @Received private let userPreferences: UserPreferences
  @Received private let statusDataControllerProvider: StatusDataControllerProvider
  @Received private let streamWatcher: StreamWatcher
  @Received private let timelineContentFilter: TimelineContentFilter
  @Received private let hapticManager: HapticManager
  let viewModel: TimelineViewModel

  public init(
    userPreferences: UserPreferences,
    statusDataControllerProvider: StatusDataControllerProvider,
    streamWatcher: StreamWatcher,
    timelineContentFilter: TimelineContentFilter,
    hapticManager: HapticManager
  ) {
    self.userPreferences = userPreferences
    self.statusDataControllerProvider = statusDataControllerProvider
    self.streamWatcher = streamWatcher
    self.timelineContentFilter = timelineContentFilter
    self.hapticManager = hapticManager
    viewModel = TimelineViewModel(
      userPreferences: userPreferences, statusDataControllerProvider: statusDataControllerProvider,
      watcher: streamWatcher, timelineContentFilter: timelineContentFilter, hapticManager: hapticManager)
  }

  /// Benchmark access to the scoped objects by name, for identity and lifetime checks.
  public var benchObjects: [String: AnyObject] {
    ["timelineViewModel": viewModel, "datasource": viewModel.datasource, "unreadObserver": viewModel.pendingStatusesObserver]
  }
}
