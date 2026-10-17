import Env
import Models
import SwiftUI
import Timeline

/// Owns one feature scope (a timeline screen) and hands its view model to TimelineView.
struct TimelineHost: View {
  @Environment(\.session) private var session
  @State private var feature: FeatureDependencies?
  @Binding var timeline: TimelineFilter
  @Binding var pinnedFilters: [TimelineFilter]
  @Binding var selectedTagGroup: TagGroup?
  let canFilterTimeline: Bool

  init(
    timeline: Binding<TimelineFilter>,
    pinnedFilters: Binding<[TimelineFilter]>,
    selectedTagGroup: Binding<TagGroup?>,
    canFilterTimeline: Bool
  ) {
    _timeline = timeline
    _pinnedFilters = pinnedFilters
    _selectedTagGroup = selectedTagGroup
    self.canFilterTimeline = canFilterTimeline
  }

  var body: some View {
    if let feature {
      TimelineView(
        timeline: $timeline, pinnedFilters: $pinnedFilters, selectedTagGroup: $selectedTagGroup,
        canFilterTimeline: canFilterTimeline, feature: feature.timelineScope)
    } else {
      Color.clear.onAppear { feature = session!.makeFeature() }
    }
  }
}
