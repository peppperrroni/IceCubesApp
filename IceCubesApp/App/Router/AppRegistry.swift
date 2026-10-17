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
    deps: AppDependencies,
    appIntentService: AppIntentService,
    namespace: Namespace.ID,
    isSupporter: Bool
  ) -> some View {
    modifier(AppDependencyGraph(deps: deps, appIntentService: appIntentService, namespace: namespace, isSupporter: isSupporter))
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
    modifier(SceneEnvironments(deps: deps))
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


/// Injects the app scope and owns the session scope: the session is replaced when the current client's id changes.
private struct AppDependencyGraph: ViewModifier {
  let deps: AppDependencies
  let appIntentService: AppIntentService
  let namespace: Namespace.ID
  let isSupporter: Bool
  @Environment(\.scenePhase) private var scenePhase
  @State private var session: SessionDependencies

  init(deps: AppDependencies, appIntentService: AppIntentService, namespace: Namespace.ID, isSupporter: Bool) {
    self.deps = deps
    self.appIntentService = appIntentService
    self.namespace = namespace
    self.isSupporter = isSupporter
    _session = State(initialValue: deps.makeSession(client: deps.appAccountsManager.currentClient))
  }

  func body(content: Content) -> some View {
    content
      .environment(deps.appAccountsManager)
      .environment(deps.hapticManager)
      .environment(deps.soundEffectManager)
      .environment(deps.statusEmbedCache)
      .environment(deps.statusDataControllerProvider)
      .environment(deps.timelineContentFilter)
      .environment(deps.quickLook)
      .environment(deps.userPreferences)
      .environment(deps.theme)
      .environment(deps.pushNotificationsService)
      .environment(appIntentService)
      .environment(deps.toastCenter)
      .environment(\.session, session)
      .environment(session.client)
      .environment(session.currentAccount)
      .environment(session.currentInstance)
      .environment(session.streamWatcher)
      .environment(\.isSupporter, isSupporter)
      .task(id: deps.appAccountsManager.currentClient.id) {
        let client = deps.appAccountsManager.currentClient
        if client.id != session.client.id {
          session.streamWatcher.stopWatching()  // the old session's socket must not outlive it
          session = deps.makeSession(client: client)  // same id keeps the session
        }
        deps.quickLook.namespace = namespace
        await session.currentInstance.fetchCurrentInstance()
        session.streamWatcher.setClient(
          client: client,
          instanceStreamingURL: session.currentInstance.instance?.urls?.streamingApi)
        if client.isAuth {
          session.streamWatcher.watch(streams: [.user, .direct])
        } else {
          session.streamWatcher.stopWatching()
        }
      }
      .task(id: deps.appAccountsManager.pushAccounts.map(\.token)) {
        deps.pushNotificationsService.tokens = deps.appAccountsManager.pushAccounts.map(\.token)
      }
      .onChange(of: scenePhase) { _, phase in
        switch phase {
        case .background: session.streamWatcher.stopWatching()
        case .active: session.streamWatcher.watch(streams: [.user, .direct])
        default: break
        }
      }
  }
}

/// For scenes that do not inherit the main window's environment: one session per scene, owned by state.
private struct SceneEnvironments: ViewModifier {
  let deps: AppDependencies
  @State private var session: SessionDependencies

  init(deps: AppDependencies) {
    self.deps = deps
    _session = State(initialValue: deps.makeSession(client: deps.appAccountsManager.currentClient))
  }

  func body(content: Content) -> some View {
    content
      .environment(session.currentAccount)
      .environment(deps.userPreferences)
      .environment(session.currentInstance)
      .environment(deps.theme)
      .environment(deps.appAccountsManager)
      .environment(deps.pushNotificationsService)
      .environment(session.client)
      .environment(session.streamWatcher)
      .environment(\.session, session)
      .environment(deps.quickLook)
      .environment(deps.toastCenter)
      .environment(deps.hapticManager)
      .environment(deps.soundEffectManager)
      .environment(deps.statusEmbedCache)
      .environment(deps.statusDataControllerProvider)
      .environment(deps.timelineContentFilter)
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
        TimelineHost(
          timeline: .constant(.hashtag(tag: tag, accountId: accountId)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false)
      case .list(let list):
        TimelineHost(
          timeline: .constant(.list(list: list)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false)
      case .collectionDetail(let collection):
        CollectionDetailView(collection: collection)
      case .linkTimeline(let url, let title):
        TimelineHost(
          timeline: .constant(.link(url: url, title: title)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false)
      case .quotes(let id):
        TimelineHost(
          timeline: .constant(.quotes(statusId: id)),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false)
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
        TimelineHost(
          timeline: .constant(.trending),
          pinnedFilters: .constant([]),
          selectedTagGroup: .constant(nil),
          canFilterTimeline: false)
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
