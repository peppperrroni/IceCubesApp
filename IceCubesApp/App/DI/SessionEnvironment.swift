import SwiftUI

private struct SessionKey: EnvironmentKey {
  static let defaultValue: SessionDependencies? = nil
}

extension EnvironmentValues {
  /// The current session root; views that create feature scopes read it.
  var session: SessionDependencies? {
    get { self[SessionKey.self] }
    set { self[SessionKey.self] = newValue }
  }
}
