import DesignSystem
import Models
import NetworkClient
import Env
import SwiftUI

@MainActor
struct NotificationRowAccessibilityActionsView: View {
  @Environment(HapticManager.self) private var hapticManager
  let accounts: [Account]
  let routerPath: RouterPath

  var body: some View {
    ForEach(accounts) { account in
      Button("@\(account.username)") {
        hapticManager.fireHaptic(.notification(.success))
        routerPath.navigate(to: .accountDetail(id: account.id))
      }
    }
  }
}
