import Foundation
import Models
import SwiftUI

@MainActor
@Observable
public class StatusEmbedCache {
  @ObservationIgnored private var cache: [URL: Status] = [:]
  @ObservationIgnored private var cacheById: [String: Status] = [:]

  @ObservationIgnored public var badStatusesURLs = Set<URL>()

  public init() {}

  public func set(url: URL, status: Status) {
    cache[url] = status
  }

  public func set(id: String, status: Status) {
    cacheById[id] = status
  }

  public func get(url: URL) -> Status? {
    cache[url]
  }

  public func get(id: String) -> Status? {
    cacheById[id]
  }
}
