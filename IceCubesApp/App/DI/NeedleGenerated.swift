

import Account
import AppAccount
import DesignSystem
import Env
import NeedleFoundation
import NetworkClient
import StatusKit
import Timeline

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = nil

// MARK: - Traversal Helpers

private func parent1(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent
}

private func parent2(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent
}

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class SessionDependencye955f30edbccda6ef7b1Provider: SessionDependency {
    var userPreferences: UserPreferences {
        return appDependencies.userPreferences
    }
    var hapticManager: HapticManager {
        return appDependencies.hapticManager
    }
    var statusDataControllerProvider: StatusDataControllerProvider {
        return appDependencies.statusDataControllerProvider
    }
    var timelineContentFilter: TimelineContentFilter {
        return appDependencies.timelineContentFilter
    }
    private let appDependencies: AppDependencies
    init(appDependencies: AppDependencies) {
        self.appDependencies = appDependencies
    }
}
/// ^->AppDependencies->SessionComponent
private func factory39df0de80ea0a8a4f36678dd37e94998a2b900ed(_ component: NeedleFoundation.Scope) -> AnyObject {
    return SessionDependencye955f30edbccda6ef7b1Provider(appDependencies: parent1(component) as! AppDependencies)
}
private class TimelineDependency38d5d2b2660d6d8eb521Provider: TimelineDependency {
    var userPreferences: UserPreferences {
        return appDependencies.userPreferences
    }
    var hapticManager: HapticManager {
        return appDependencies.hapticManager
    }
    var statusDataControllerProvider: StatusDataControllerProvider {
        return appDependencies.statusDataControllerProvider
    }
    var timelineContentFilter: TimelineContentFilter {
        return appDependencies.timelineContentFilter
    }
    var streamWatcher: StreamWatcher {
        return sessionComponent.streamWatcher
    }
    private let appDependencies: AppDependencies
    private let sessionComponent: SessionComponent
    init(appDependencies: AppDependencies, sessionComponent: SessionComponent) {
        self.appDependencies = appDependencies
        self.sessionComponent = sessionComponent
    }
}
/// ^->AppDependencies->SessionComponent->TimelineComponent
private func factory512c78c956f467f411fcfbb6a646b5a2dac84f73(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TimelineDependency38d5d2b2660d6d8eb521Provider(appDependencies: parent2(component) as! AppDependencies, sessionComponent: parent1(component) as! SessionComponent)
}

#else
extension SessionComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\SessionDependency.userPreferences] = "userPreferences-UserPreferences"
        keyPathToName[\SessionDependency.hapticManager] = "hapticManager-HapticManager"
        keyPathToName[\SessionDependency.statusDataControllerProvider] = "statusDataControllerProvider-StatusDataControllerProvider"
        keyPathToName[\SessionDependency.timelineContentFilter] = "timelineContentFilter-TimelineContentFilter"
        localTable["client-MastodonClient"] = { [unowned self] in self.client as Any }
        localTable["currentAccount-CurrentAccount"] = { [unowned self] in self.currentAccount as Any }
        localTable["currentInstance-CurrentInstance"] = { [unowned self] in self.currentInstance as Any }
        localTable["streamWatcher-StreamWatcher"] = { [unowned self] in self.streamWatcher as Any }
        localTable["timelineComponent-TimelineComponent"] = { [unowned self] in self.timelineComponent as Any }
    }
}
extension AppDependencies: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["theme-Theme"] = { [unowned self] in self.theme as Any }
        localTable["userPreferences-UserPreferences"] = { [unowned self] in self.userPreferences as Any }
        localTable["hapticManager-HapticManager"] = { [unowned self] in self.hapticManager as Any }
        localTable["soundEffectManager-SoundEffectManager"] = { [unowned self] in self.soundEffectManager as Any }
        localTable["appAccountsManager-AppAccountsManager"] = { [unowned self] in self.appAccountsManager as Any }
        localTable["pushNotificationsService-PushNotificationsService"] = { [unowned self] in self.pushNotificationsService as Any }
        localTable["quickLook-QuickLook"] = { [unowned self] in self.quickLook as Any }
        localTable["toastCenter-ToastCenter"] = { [unowned self] in self.toastCenter as Any }
        localTable["statusEmbedCache-StatusEmbedCache"] = { [unowned self] in self.statusEmbedCache as Any }
        localTable["statusDataControllerProvider-StatusDataControllerProvider"] = { [unowned self] in self.statusDataControllerProvider as Any }
        localTable["timelineContentFilter-TimelineContentFilter"] = { [unowned self] in self.timelineContentFilter as Any }
    }
}
extension TimelineComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\TimelineDependency.userPreferences] = "userPreferences-UserPreferences"
        keyPathToName[\TimelineDependency.hapticManager] = "hapticManager-HapticManager"
        keyPathToName[\TimelineDependency.statusDataControllerProvider] = "statusDataControllerProvider-StatusDataControllerProvider"
        keyPathToName[\TimelineDependency.timelineContentFilter] = "timelineContentFilter-TimelineContentFilter"
        keyPathToName[\TimelineDependency.streamWatcher] = "streamWatcher-StreamWatcher"
    }
}


#endif

private func factoryEmptyDependencyProvider(_ component: NeedleFoundation.Scope) -> AnyObject {
    return EmptyDependencyProvider(component: component)
}

// MARK: - Registration
private func registerProviderFactory(_ componentPath: String, _ factory: @escaping (NeedleFoundation.Scope) -> AnyObject) {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: componentPath, factory)
}

#if !NEEDLE_DYNAMIC

@inline(never) private func register1() {
    registerProviderFactory("^->AppDependencies->SessionComponent", factory39df0de80ea0a8a4f36678dd37e94998a2b900ed)
    registerProviderFactory("^->AppDependencies", factoryEmptyDependencyProvider)
    registerProviderFactory("^->AppDependencies->SessionComponent->TimelineComponent", factory512c78c956f467f411fcfbb6a646b5a2dac84f73)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
