import AVFoundation
import Account
import NeedleFoundation
import AppAccount
import DesignSystem
import Env
import KeychainSwift
import MediaUI
import NetworkClient
import RevenueCat
import StatusKit
import SwiftUI
import Timeline

#if !targetEnvironment(macCatalyst)
  import WishKit
#endif

@main
struct IceCubesApp: App {
  @UIApplicationDelegateAdaptor var appDelegate: AppDelegate

  @Environment(\.scenePhase) var scenePhase
  @Environment(\.openWindow) var openWindow

  let deps: AppDependencies
  @State var appAccountsManager: AppAccountsManager
  @State var currentInstance: CurrentInstance
  @State var currentAccount: CurrentAccount
  @State var userPreferences: UserPreferences
  @State var pushNotificationsService: PushNotificationsService
  @State var appIntentService = AppIntentService.shared
  @State var watcher: StreamWatcher
  @State var quickLook: QuickLook
  @State var theme: DesignSystem.Theme
  @State var toastCenter: ToastCenter

  @State var selectedTab: AppTab = .timeline
  @State var appRouterPath = RouterPath()

  @State var isSupporter: Bool = false
  
  @Namespace var namespace

  init() {
    registerProviderFactories()  // Needle: must precede any Component creation
    deps = AppDependencies()
    // Static helpers with no owner (Font, layoutPadding, DeepL key) read these.
    Theme.current = deps.theme
    UserPreferences.current = deps.userPreferences
    let benchDeps = deps  // local copy: the closure must not capture self during init
    BenchHooks.start { BenchResolve.resolveAll(benchDeps) }
    _appAccountsManager = State(initialValue: deps.appAccountsManager)
    _currentInstance = State(initialValue: deps.currentInstance)
    _currentAccount = State(initialValue: deps.currentAccount)
    _userPreferences = State(initialValue: deps.userPreferences)
    _pushNotificationsService = State(initialValue: deps.pushNotificationsService)
    _watcher = State(initialValue: deps.streamWatcher)
    _quickLook = State(initialValue: deps.quickLook)
    _theme = State(initialValue: deps.theme)
    _toastCenter = State(initialValue: deps.toastCenter)
    deps.pushNotificationsService.setAccounts(accounts: deps.appAccountsManager.pushAccounts)
    #if DEBUG
      UserDefaults.standard.register(defaults: [
        "com.apple.SwiftUI.GraphReuseLogging": true, // Enable "GraphReuseLogging" by default. The log can be found via - subsystem: "com.apple.SwiftUI" category: "GraphReuse"
        "LogForEachSlowPath": true, // Enable "LogForEachSlowPath" by default. The log can be found via - subsystem: "com.apple.SwiftUI" category: "Invalid Configuration"
      ])
    #endif
  }

  var body: some Scene {
    appScene
    otherScenes
  }

  func handleScenePhase(scenePhase: ScenePhase) {
    switch scenePhase {
    case .background:
      watcher.stopWatching()
    case .active:
      watcher.watch(streams: [.user, .direct])
      UNUserNotificationCenter.current().setBadgeCount(0)
      userPreferences.reloadNotificationsCount(
        tokens: appAccountsManager.availableAccounts.compactMap(\.oauthToken))
      Task {
        await userPreferences.refreshServerPreferences()
      }
    default:
      break
    }
  }

  func setupRevenueCat() {
    Purchases.logLevel = .error
    Purchases.configure(withAPIKey: "appl_JXmiRckOzXXTsHKitQiicXCvMQi")
    Purchases.shared.getCustomerInfo { info, _ in
      if info?.entitlements["Supporter"]?.isActive == true {
        isSupporter = true
      }
    }
  }

  func refreshPushSubs() {
    pushNotificationsService.requestPushNotifications()
  }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
  // Installed by IceCubesApp on first appearance; the launch-time registration moved to IceCubesApp.init.
  var pushNotificationsService: PushNotificationsService?
  var appAccountsManager: AppAccountsManager?

  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
    try? AVAudioSession.sharedInstance().setActive(true)
    Telemetry.setup()
    Telemetry.signal("app.launched")
    #if !targetEnvironment(macCatalyst)
      WishKit.configure(with: "AF21AE07-3BA9-4FE2-BFB1-59A3B3941730")
    #endif
    return true
  }

  func application(
    _: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    guard let pushNotificationsService, let appAccountsManager else { return }
    pushNotificationsService.pushToken = deviceToken
    Task {
      pushNotificationsService.setAccounts(accounts: appAccountsManager.pushAccounts)
      await pushNotificationsService.updateSubscriptions(forceCreate: false)
    }
  }

  func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {}

  func application(_: UIApplication, didReceiveRemoteNotification _: [AnyHashable: Any]) async
    -> UIBackgroundFetchResult
  {
    return .noData
  }
  

  func application(
    _: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    if connectingSceneSession.role == .windowApplication {
      configuration.delegateClass = SceneDelegate.self
    }
    return configuration
  }

  override func buildMenu(with builder: UIMenuBuilder) {
    super.buildMenu(with: builder)
    builder.remove(menu: .document)
    builder.remove(menu: .toolbar)
  }
}
