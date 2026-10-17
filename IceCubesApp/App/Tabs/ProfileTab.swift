import Account
import AppAccount
import Conversations
import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
struct ProfileTab: View {
  @Environment(StatusEmbedCache.self) private var statusEmbedCache
  @Environment(AppAccountsManager.self) private var appAccount
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client
  @Environment(CurrentAccount.self) private var currentAccount
  @State private var routerPath = RouterPath()

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      if let account = currentAccount.account {
        AccountDetailView(account: account)
          .withAppRouter()
          .withSheetDestinations(
            sheetDestinations: $routerPath.presentedSheet,
            routerPath: routerPath
          )
          .id(account.id)
      } else {
        AccountDetailView(account: .placeholder())
          .redacted(reason: .placeholder)
          .allowsHitTesting(false)
      }
    }
    .onChange(of: client.id) {
      routerPath.path = []
    }
    .onAppear {
      routerPath.client = client
      routerPath.statusEmbedCache = statusEmbedCache
    }
    .withSafariRouter()
    .environment(routerPath)
  }
}
