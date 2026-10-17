import AVKit
import AudioToolbox
import CoreHaptics
import UIKit

@MainActor
@Observable
public class SoundEffectManager {

  public enum SoundEffect: String, CaseIterable {
    case pull, refresh, tootSent, tabSelection, bookmark, boost, favorite, share
  }

  @ObservationIgnored private var systemSoundIDs: [SoundEffect: SystemSoundID] = [:]

  private let userPreferences: UserPreferences

  public init(userPreferences: UserPreferences) {
    self.userPreferences = userPreferences
    registerSounds()
  }

  private func registerSounds() {
    SoundEffect.allCases.forEach { effect in
      guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else {
        return
      }
      register(url: url, for: effect)
    }
  }

  private func register(url: URL, for effect: SoundEffect) {
    var soundId: SystemSoundID = .init()
    AudioServicesCreateSystemSoundID(url as CFURL, &soundId)
    systemSoundIDs[effect] = soundId
  }

  public func playSound(_ effect: SoundEffect) {
    guard
      userPreferences.soundEffectEnabled,
      let soundId = systemSoundIDs[effect]
    else {
      return
    }

    AudioServicesPlaySystemSound(soundId)
  }
}
