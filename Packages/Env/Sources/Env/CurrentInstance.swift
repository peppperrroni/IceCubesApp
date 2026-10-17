import SafeDI
import Combine
import Foundation
import Models
import NetworkClient
import Observation

@MainActor
@Instantiable
@Observable public class CurrentInstance: Instantiable {
  public private(set) var instance: Instance?

  /// SafeDI needs the dependency as an immutable decorated property; `activeClient` keeps the
  /// pre-existing mutable behaviour of `setClient` (used by the editor account picker).
  @Received private let client: MastodonClient
  private var activeClient: MastodonClient?

  private var version: Float {
    if let stringVersion = instance?.version {
      if stringVersion.utf8.count > 2 {
        return Float(stringVersion.prefix(3)) ?? 0
      } else {
        return Float(stringVersion.prefix(1)) ?? 0
      }
    }
    return 0
  }

  public var isFiltersSupported: Bool {
    version >= 4
  }

  public var isEditSupported: Bool {
    version >= 3.5
  }

  public var isEditAltTextSupported: Bool {
    version >= 4.1
  }

  public var isNotificationsFilterSupported: Bool {
    version >= 4.3
  }

  public var isLinkTimelineSupported: Bool {
    version >= 4.3
  }

  public var isGroupedNotificationsSupported: Bool {
    version >= 4.3
  }

  /// Collections shipped in Mastodon 4.6, which bumped the Mastodon API version to 10.
  public var isCollectionsSupported: Bool {
    instance?.apiVersions?.mastodon ?? 0 >= 10
  }

  public var isQuoteSupported: Bool {
    instance?.apiVersions?.mastodon ?? 0 >= 7
  }

  public var canViewStatusQuotes: Bool {
    instance?.apiVersions?.mastodon ?? 0 >= 7
  }

  public init(client: MastodonClient) {
    self.client = client
    setClient(client: client)
  }

  public func setClient(client: MastodonClient) {
    activeClient = client
  }

  public func fetchCurrentInstance() async {
    guard let client = activeClient else { return }
    instance = try? await client.get(endpoint: Instances.instance, forceVersion: .v2)
  }
}
