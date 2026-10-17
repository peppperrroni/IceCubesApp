import Foundation
import NetworkClient

/// Per-variant adapter so the shared scope checks never touch framework types.
@MainActor
struct BenchScopeAccess {
  /// The variant's session object for a client.
  let makeSession: (MastodonClient) -> AnyObject
  /// "client", "currentAccount", "currentInstance", "streamWatcher"
  let sessionObjects: (AnyObject) -> [String: AnyObject]
  /// A feature object under a session.
  let makeFeature: (AnyObject) -> AnyObject
  /// "timelineViewModel", "datasource", "unreadObserver"
  let featureObjects: (AnyObject) -> [String: AnyObject]
  /// Make app-scope caches touch the session, so cross-scope retention can be probed.
  let appObjectsUsing: (AnyObject) -> Void
}
