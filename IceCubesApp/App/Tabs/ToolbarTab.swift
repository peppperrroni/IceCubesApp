import AppAccount
import DesignSystem
import Env
import SwiftUI

@MainActor
struct ToolbarTab: ToolbarContent {
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @Environment(UserPreferences.self) private var userPreferences

  @Binding var routerPath: RouterPath
  
  @Namespace private var transition

  var body: some ToolbarContent {
    if !isSecondaryColumn {
      statusEditorToolbarItem(
        routerPath: routerPath,
        visibility: userPreferences.postVisibility)
      if #available(iOS 26.0, *) {
        #if os(iOS) && !targetEnvironment(macCatalyst)
          accountToolbarItem
        #else
          accountToolbarItem
        #endif
      } else {
        ToolbarItem(placement: .navigationBarLeading) {
          accountSelector
        }
      }
    }
    if UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular {
      if (!isSecondaryColumn && !userPreferences.showiPadSecondaryColumn) || isSecondaryColumn {
        SecondaryColumnToolbarItem()
      }
    }
  }

  @available(iOS 26.0, *)
  private var accountToolbarItem: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      #if targetEnvironment(macCatalyst)
        accountSelector
      #elseif os(iOS)
        accountSelector
          .offset(x: -12)
      #else
        accountSelector
          .offset(x: -12)
      #endif
    }
    .matchedTransitionSource(id: currentAccount.account?.id ?? "", in: transition)
    .sharedBackgroundVisibility(.hidden)
  }

  private var accountSelector: some View {
    AppAccountsSelectorView(
      transition: transition,
      routerPath: routerPath,
      avatarConfig: .embed)
      #if targetEnvironment(macCatalyst)
        .buttonStyle(.plain)
      #endif
  }
}

