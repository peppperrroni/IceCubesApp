import SwiftUI
import StatusKit
import NetworkClient
import Env
import Models
import DesignSystem

struct AnyStatusesListView: View {
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(StatusEmbedCache.self) private var statusEmbedCache
  @Environment(StreamWatcher.self) private var watcher
  let fetcher: any StatusesFetcher
  let client: MastodonClient
  let routerPath: RouterPath
  
  @Environment(Theme.self) private var theme
  
  var body: some View {
    switch fetcher.statusesState {
    case .loading:
      ForEach(Status.placeholders()) { status in
        StatusRowExternalView(
          viewModel: .init(
            status: status,
            client: client,
            routerPath: routerPath,
            filterContext: .account,
              theme: theme, userPreferences: userPreferences, currentAccount: currentAccount, statusEmbedCache: statusEmbedCache, watcher: watcher)
        )
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
      }
    case let .display(statuses, nextPageState):
      ForEach(statuses) { status in
        StatusRowExternalView(
          viewModel: .init(
            status: status,
            client: client,
            routerPath: routerPath,
            filterContext: .account,
              theme: theme, userPreferences: userPreferences, currentAccount: currentAccount, statusEmbedCache: statusEmbedCache, watcher: watcher)
        )
      }
      
      if nextPageState == .hasNextPage {
        loadMoreView
          .onAppear {
            Task {
              try? await fetcher.fetchNextPage()
            }
          }
      }
    case .error:
      ErrorView(
        title: "status.error.title",
        message: "status.error.loading.message",
        buttonTitle: "action.retry"
      ) {
        Task {
          await fetcher.fetchNewestStatuses(pullToRefresh: false)
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      .listRowSeparator(.hidden)
    case .displayWithGaps:
      EmptyView()
    }
  }
  
  private var loadMoreView: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .padding()
    .listRowBackground(theme.primaryBackgroundColor)
  }
}
