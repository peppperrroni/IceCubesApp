import Account
import AppAccount
import Conversations
import DesignSystem
import Env
import Explore
import LinkPresentation
import Lists
import MediaUI
import Models
import Notifications
import StatusKit
import SwiftUI
import Timeline

@MainActor
extension View {
  func withAppDependencyGraph(
    appAccountsManager: AppAccountsManager,
    currentAccount: CurrentAccount,
    currentInstance: CurrentInstance,
    userPreferences: UserPreferences,
    theme: Theme,
    watcher: StreamWatcher,
    pushNotificationsService: PushNotificationsService,
    appIntentService: AppIntentService,
    quickLook: QuickLook,
    toastCenter: ToastCenter,
    hapticManager: HapticManager,
    soundEffectManager: SoundEffectManager,
    statusEmbedCache: StatusEmbedCache,
    statusDataControllerProvider: StatusDataControllerProvider,
    timelineContentFilter: TimelineContentFilter,
    namespace: Namespace.ID,
    isSupporter: Bool
  ) -> some View {
    environment(appAccountsManager)
      .environment(hapticManager)
      .environment(soundEffectManager)
      .environment(statusEmbedCache)
      .environment(statusDataControllerProvider)
      .environment(timelineContentFilter)
      .environment(appAccountsManager.currentClient)
      .environment(quickLook)
      .environment(currentAccount)
      .environment(currentInstance)
      .environment(userPreferences)
      .environment(theme)
      .environment(watcher)
      .environment(pushNotificationsService)
      .environment(appIntentService)
      .environment(toastCenter)
      .environment(\.isSupporter, isSupporter)
      .task(id: appAccountsManager.currentClient.id) {
        let client = appAccountsManager.currentClient
        quickLook.namespace = namespace
        currentAccount.setClient(client: client)
        currentInstance.setClient(client: client)
        userPreferences.setClient(client: client)
        await currentInstance.fetchCurrentInstance()
        watcher.setClient(
          client: client,
          instanceStreamingURL: currentInstance.instance?.urls?.streamingApi)
        if client.isAuth {
          watcher.watch(streams: [.user, .direct])
        } else {
          watcher.stopWatching()
        }
      }
      .task(id: appAccountsManager.pushAccounts.map(\.token)) {
        pushNotificationsService.tokens = appAccountsManager.pushAccounts.map(\.token)
      }
  }

  func withAppRouter() -> some View {
    modifier(AppRouter())
  }

  func withSheetDestinations(
    sheetDestinations: Binding<SheetDestination?>,
    routerPath: RouterPath
  ) -> some View {
    modifier(SheetDestinations(sheetDestinations: sheetDestinations, routerPath: routerPath))
  }

  /// Re-applies the environment objects already in scope (sheets and nested stacks keep them).
  func withEnvironments() -> some View {
    modifier(ReinjectEnvironments())
  }

  /// For scenes that do not inherit the main window's environment.
  func withEnvironments(_ deps: AppDependencies) -> some View {
    environment(deps.currentAccount)
      .environment(deps.userPreferences)
      .environment(deps.currentInstance)
      .environment(deps.theme)
      .environment(deps.appAccountsManager)
      .environment(deps.pushNotificationsService)
      .environment(deps.appAccountsManager.currentClient)
      .environment(deps.quickLook)
      .environment(deps.toastCenter)
      .environment(deps.hapticManager)
      .environment(deps.soundEffectManager)
      .environment(deps.statusEmbedCache)
      .environment(deps.statusDataControllerProvider)
      .environment(deps.timelineContentFilter)
  }

  func withModelContainer() -> some View {
    modelContainer(for: [
      Draft.self,
      LocalTimeline.self,
      TagGroup.self,
      RecentTag.self,
      MetricsNotificationGroup.self,
    ])
  }
}


private struct AppRouter: ViewModifier {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(PushNotificationsService.self) private var pushNotificationsService
  @Environment(StreamWatcher.self) private var watcher
  @Environment(QuickLook.self) private var quickLook
  @Environment(ToastCenter.self) private var toastCenter
  @Environment(HapticManager.self) private var hapticManager
  @Environment(StatusEmbedCache.self) private var statusEmbedCache
  @Environment(StatusDataControllerProvider.self) private var statusDataControllerProvider
  @Environment(TimelineContentFilter.self) private var timelineContentFilter

  func body(content: Content) -> some View {
    content.navigationDestination(for: RouterDestination.self) { destination in
      switch destination {
      case .accountDetail(let id):
        AccountDetailView(accountId: id)
      case .accountDetailWithAccount(let account):
        AccountDetailView(account: account)
      case .accountSettingsWithAccount(let account, let appAccount):
        AccountSettingsView(account: account, appAccount: appAccount)
      case .accountMediaGridView(let account, let initialMedia):
        AccountDetailMediaGridView(account: account, initialMediaStatuses: initialMedia)
      case .statusDetail(let id):
        StatusDetailView(statusId: id, statusDataControllerProvider: statusDataControllerProvider)
      case .statusDetailWithStatus(let status):
        StatusDetailView(status: status, statusDataControllerProvider: statusDataControllerProvider)
      case .remoteStatusDetail(let url):
        StatusDetailView(remoteStatusURL: url, statusDataControllerProvider: statusDataControllerProvider)
      case .conversationDetail(let conversation):
        ConversationDetailView(conversation: conversation)
      case .hashTag(let tag, let accountId):
        TimelineView(
          timeline: .constant(.hashtag(tag: tag, accountId: accountId)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false,
          userPreferences: userPreferences, statusDataControllerProvider: statusDataControllerProvider,
          watcher: watcher, timelineContentFilter: timelineContentFilter, hapticManager: hapticManager)
      case .list(let list):
        TimelineView(
          timeline: .constant(.list(list: list)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false,
          userPreferences: userPreferences, statusDataControllerProvider: statusDataControllerProvider,
          watcher: watcher, timelineContentFilter: timelineContentFilter, hapticManager: hapticManager)
      case .collectionDetail(let collection):
        CollectionDetailView(collection: collection)
      case .linkTimeline(let url, let title):
        TimelineView(
          timeline: .constant(.link(url: url, title: title)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false,
          userPreferences: userPreferences, statusDataControllerProvider: statusDataControllerProvider,
          watcher: watcher, timelineContentFilter: timelineContentFilter, hapticManager: hapticManager)
      case .quotes(let id):
        TimelineView(
          timeline: .constant(.quotes(statusId: id)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false,
          userPreferences: userPreferences, statusDataControllerProvider: statusDataControllerProvider,
          watcher: watcher, timelineContentFilter: timelineContentFilter, hapticManager: hapticManager)
      case .following(let id):
        AccountsListView(mode: .following(accountId: id))
      case .followers(let id):
        AccountsListView(mode: .followers(accountId: id))
      case .favoritedBy(let id):
        AccountsListView(mode: .favoritedBy(statusId: id))
      case .rebloggedBy(let id):
        AccountsListView(mode: .rebloggedBy(statusId: id))
      case .accountsList(let accounts):
        AccountsListView(mode: .accountsList(accounts: accounts))
      case .trendingTimeline:
        TimelineView(
          timeline: .constant(.trending),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false,
          userPreferences: userPreferences, statusDataControllerProvider: statusDataControllerProvider,
          watcher: watcher, timelineContentFilter: timelineContentFilter, hapticManager: hapticManager)
      case .trendingLinks(let cards):
        TrendingLinksListView(cards: cards)
      case .tagsList(let tags):
        TagsListView(tags: tags)
      case .notificationsRequests:
        NotificationsRequestsListView()
      case .notificationForAccount(let accountId):
        NotificationsListView(
          lockedType: nil,
          lockedAccountId: accountId,
          currentInstance: currentInstance)
      case .blockedAccounts:
        AccountsListView(mode: .blocked)
      case .mutedAccounts:
        AccountsListView(mode: .muted)
      case .conversations:
        ConversationsListView()
      case .instanceInfo(let instance):
        InstanceInfoView(instance: instance)
      case .metrics:
        AccountMetricsView()
      }
    }
  }
}

private struct SheetDestinations: ViewModifier {
  let sheetDestinations: Binding<SheetDestination?>
  let routerPath: RouterPath
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(PushNotificationsService.self) private var pushNotificationsService
  @Environment(StreamWatcher.self) private var watcher
  @Environment(QuickLook.self) private var quickLook
  @Environment(ToastCenter.self) private var toastCenter
  @Environment(HapticManager.self) private var hapticManager
  @Environment(StatusEmbedCache.self) private var statusEmbedCache
  @Environment(StatusDataControllerProvider.self) private var statusDataControllerProvider
  @Environment(TimelineContentFilter.self) private var timelineContentFilter

  func body(content: Content) -> some View {
    content.sheet(item: sheetDestinations) { destination in
      Group {
        switch destination {
        case .replyToStatusEditor(let status):
          StatusEditor.MainView(mode: .replyTo(status: status))
            .withEnvironments()
        case .newStatusEditor(let visibility):
          StatusEditor.MainView(mode: .new(text: nil, visibility: visibility))
            .withEnvironments()
        case .prefilledStatusEditor(let text, let visibility):
          StatusEditor.MainView(mode: .new(text: text, visibility: visibility))
            .withEnvironments()
        case .imageURL(let urls, let caption, let altTexts, let visibility):
          StatusEditor.MainView(
            mode: .imageURL(
              urls: urls, caption: caption, altTexts: altTexts, visibility: visibility)
          )
          .withEnvironments()
        case .editStatusEditor(let status):
          StatusEditor.MainView(mode: .edit(status: status))
            .withEnvironments()
        case .quoteStatusEditor(let status):
          StatusEditor.MainView(mode: .quote(status: status))
            .withEnvironments()
        case .quoteLinkStatusEditor(let link):
          StatusEditor.MainView(mode: .quoteLink(link: link))
            .withEnvironments()
        case .mentionStatusEditor(let account, let visibility):
          StatusEditor.MainView(mode: .mention(account: account, visibility: visibility))
            .withEnvironments()
        case .listCreate:
          ListCreateView()
            .withEnvironments()
        case .listEdit(let list):
          ListEditView(list: list, currentAccount: currentAccount)
            .withEnvironments()
        case .listAddAccount(let account):
          ListAddAccountView(account: account)
            .withEnvironments()
        case .addAccount:
          AddAccountView()
            .withEnvironments()
        case .addRemoteLocalTimeline:
          AddRemoteTimelineView()
            .withEnvironments()
        case .addTagGroup:
          EditTagGroupView()
            .withEnvironments()
        case .statusEditHistory(let status):
          StatusEditHistoryView(statusId: status)
            .withEnvironments()
        case .settings:
          SettingsTabs(isModal: true)
            .withEnvironments()
            .preferredColorScheme(theme.selectedScheme == .dark ? .dark : .light)
        case .accountPushNotficationsSettings:
          if let subscription = pushNotificationsService.subscriptions.first(where: {
            $0.account.token == appAccountsManager.currentAccount.oauthToken
          }) {
            NavigationSheet { PushNotificationsView(subscription: subscription) }
              .withEnvironments()
          } else {
            EmptyView()
          }
        case .about:
          NavigationSheet { AboutView() }
            .withEnvironments()
        case .support:
          NavigationSheet { SupportAppView() }
            .withEnvironments()
        case .report(let status):
          ReportView(status: status)
            .withEnvironments()
        case .shareImage(let image, let status):
          ActivityView(image: image, status: status)
            .withEnvironments()
        case .editTagGroup(let tagGroup, let onSaved):
          EditTagGroupView(tagGroup: tagGroup, onSaved: onSaved)
            .withEnvironments()
        case .timelineContentFilter:
          TimelineContentFilterView()
            .withEnvironments()
        case .accountEditInfo:
          EditAccountView()
            .withEnvironments()
        case .accountFiltersList:
          FiltersListView()
            .withEnvironments()
        }
      }
      .environment(routerPath)
    }
  }
}

private struct ReinjectEnvironments: ViewModifier {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(PushNotificationsService.self) private var pushNotificationsService
  @Environment(StreamWatcher.self) private var watcher
  @Environment(QuickLook.self) private var quickLook
  @Environment(ToastCenter.self) private var toastCenter
  @Environment(HapticManager.self) private var hapticManager
  @Environment(StatusEmbedCache.self) private var statusEmbedCache
  @Environment(StatusDataControllerProvider.self) private var statusDataControllerProvider
  @Environment(TimelineContentFilter.self) private var timelineContentFilter

  func body(content: Content) -> some View {
    content
      .environment(currentAccount)
      .environment(userPreferences)
      .environment(currentInstance)
      .environment(theme)
      .environment(appAccountsManager)
      .environment(pushNotificationsService)
      .environment(appAccountsManager.currentClient)
      .environment(quickLook)
      .environment(toastCenter)
  }
}


struct ActivityView: UIViewControllerRepresentable {
  let image: UIImage
  let status: Status

  class LinkDelegate: NSObject, UIActivityItemSource {
    let image: UIImage
    let status: Status

    init(image: UIImage, status: Status) {
      self.image = image
      self.status = status
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
      let imageProvider = NSItemProvider(object: image)
      let metadata = LPLinkMetadata()
      metadata.imageProvider = imageProvider
      metadata.title = status.reblog?.content.asRawText ?? status.content.asRawText
      return metadata
    }

    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
      image
    }

    func activityViewController(
      _: UIActivityViewController,
      itemForActivityType _: UIActivity.ActivityType?
    ) -> Any? {
      nil
    }
  }

  func makeUIViewController(context _: UIViewControllerRepresentableContext<ActivityView>)
    -> UIActivityViewController
  {
    UIActivityViewController(
      activityItems: [image, LinkDelegate(image: image, status: status)],
      applicationActivities: nil)
  }

  func updateUIViewController(
    _: UIActivityViewController, context _: UIViewControllerRepresentableContext<ActivityView>
  ) {}
}

extension URL: @retroactive Identifiable {
  public var id: String {
    absoluteString
  }
}
