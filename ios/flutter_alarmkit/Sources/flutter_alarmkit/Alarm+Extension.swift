import Foundation
import AlarmKit
import SwiftUI

@available(iOS 26.0, *)
extension Alarm {
  /// Serializes this alarm into the dictionary contract consumed by the Dart
  /// `Alarm.fromMap`. Never returns `nil`: an unrecognized state or schedule
  /// kind is reported as `"unknown"` rather than dropping the alarm.
  func toDictionary() -> [String: Any] {
      var dict: [String: Any] = [:]
      dict["id"] = self.id.uuidString

      // Schedule. A countdown timer has a nil schedule, in which case we omit
      // the key entirely (the timing lives in `countdownDuration` below).
      if let schedule = self.schedule {
          var scheduleDict: [String: Any] = [:]
          switch schedule {
          case .fixed(let date):
              scheduleDict["type"] = "fixed"
              scheduleDict["timestamp"] = date.timeIntervalSince1970 * 1000
          case .relative(let relativeSchedule):
              scheduleDict["type"] = "relative"
              scheduleDict["hour"] = relativeSchedule.time.hour
              scheduleDict["minute"] = relativeSchedule.time.minute
              switch relativeSchedule.repeats {
              case .never:
                  scheduleDict["weekdayMask"] = 0
              case .weekly(let days):
                  scheduleDict["weekdayMask"] = encodeWeekdays(days)
              @unknown default:
                  scheduleDict["weekdayMask"] = 0
              }
          @unknown default:
              scheduleDict["type"] = "unknown"
          }
          dict["schedule"] = scheduleDict
      }

      // Countdown timing, when present (each field is independently optional).
      if let countdown = self.countdownDuration {
          var countdownDict: [String: Any] = [:]
          if let preAlert = countdown.preAlert {
              countdownDict["preAlert"] = preAlert
          }
          if let postAlert = countdown.postAlert {
              countdownDict["postAlert"] = postAlert
          }
          dict["countdownDuration"] = countdownDict
      }

      // State.
      switch self.state {
      case .scheduled:
          dict["state"] = "scheduled"
      case .countdown:
          dict["state"] = "countdown"
      case .paused:
          dict["state"] = "paused"
      case .alerting:
          dict["state"] = "alerting"
      @unknown default:
          dict["state"] = "unknown"
      }

      // Presentation metadata (label + tint) is not readable back from
      // AlarmKit, so the plugin persists it in the App Group at schedule time;
      // merge it in here when available.
      if let defaults = UserDefaults(suiteName: AlarmkitPluginImpl.appGroupId),
         let meta = defaults.dictionary(forKey: "alarm_meta_\(self.id.uuidString)") {
          if let label = meta["label"] as? String {
              dict["label"] = label
          }
          if let tintColor = meta["tintColor"] as? String {
              dict["tintColor"] = tintColor
          }
      }

      return dict
  }
}

/// Encodes AlarmKit weekdays back into the monday=bit0 bitmask used across the
/// plugin (inverse of `decodeWeekdays` in `FlutterAlarmkitPlugin.swift`, and
/// matching the Dart `Weekday.toBitmask` ordering).
@available(iOS 26.0, *)
private func encodeWeekdays(_ days: [Locale.Weekday]) -> Int {
    var mask = 0
    for day in days {
        switch day {
        case .monday: mask |= (1 << 0)
        case .tuesday: mask |= (1 << 1)
        case .wednesday: mask |= (1 << 2)
        case .thursday: mask |= (1 << 3)
        case .friday: mask |= (1 << 4)
        case .saturday: mask |= (1 << 5)
        case .sunday: mask |= (1 << 6)
        @unknown default: break
        }
    }
    return mask
}
