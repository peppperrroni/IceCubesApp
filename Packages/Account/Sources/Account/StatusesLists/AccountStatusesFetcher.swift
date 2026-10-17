import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

@MainActor
@Observable
class AccountStatusesFetcher: StatusesFetcher {
  let mode: AccountStatusesListView.Mode
  var statusesState: StatusesState = .loading
  var statuses: [Status] = []
  var nextPage: LinkHandler?
  var client: MastodonClient?

  private let statusDataControllerProvider: StatusDataControllerProvider

  init(mode: AccountStatusesListView.Mode, statusDataControllerProvider: StatusDataControllerProvider) {
    self.mode = mode
    self.statusDataControllerProvider = statusDataControllerProvider
  }

  func fetchNewestStatuses(pullToRefresh: Bool) async {
    guard let client else { return }
    statusesState = .loading
    do {
      (statuses, nextPage) = try await client.getWithLink(endpoint: mode.endpoint(sinceId: nil))
      statusDataControllerProvider.updateDataControllers(for: statuses, client: client)
      statusesState = .display(
        statuses: statuses,
        nextPageState: nextPage?.maxId != nil ? .hasNextPage : .none)
    } catch {
      statusesState = .error(error: .noData)
    }
  }

  func fetchNextPage() async throws {
    guard let client, let nextId = nextPage?.maxId else { return }
    var newStatuses: [Status] = []
    (newStatuses, nextPage) = try await client.getWithLink(endpoint: mode.endpoint(sinceId: nextId))
    statuses.append(contentsOf: newStatuses)
    statusDataControllerProvider.updateDataControllers(for: statuses, client: client)
    statusesState = .display(
      statuses: statuses,
      nextPageState: nextPage?.maxId != nil ? .hasNextPage : .none)
  }

  func statusDidAppear(status: Status) {}

  func statusDidDisappear(status: Status) {}
}
