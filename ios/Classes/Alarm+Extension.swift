import Foundation
import AlarmKit
import SwiftUI

@available(iOS 26.0, *)
extension Alarm {
  func toDictionary() -> [String: Any]? {
      var dict: [String: Any] = [:]
      dict["id"] = self.id.uuidString

      var scheduleDict: [String: Any] = [:]
      if let schedule = self.schedule {
          switch schedule {
          case .fixed(let date):
              scheduleDict["type"] = "fixed"
              scheduleDict["timestamp"] = date.timeIntervalSince1970 * 1000
          case .relative(let relativeSchedule):
              scheduleDict["type"] = "relative"
              scheduleDict["hour"] = relativeSchedule.time.hour
              scheduleDict["minute"] = relativeSchedule.time.minute
          @unknown default:
              return nil
          }
      } else {
          // Countdown alarms have a nil schedule.
          scheduleDict["type"] = "countdown"
      }
      dict["schedule"] = scheduleDict

      switch self.state {
      case .scheduled:
          dict["state"] = "scheduled"
      case .paused:
          dict["state"] = "paused"
      @unknown default:
          dict["state"] = "unknown"
      }
      return dict
  }
} 