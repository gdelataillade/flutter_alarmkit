import Foundation
import AlarmKit
import SwiftUI

@available(iOS 26.0, *)
extension Alarm {
  var alertingTime: Date? {
    guard let schedule else { return nil }

    switch schedule {
      case .fixed(let date):
        return date
      case .relative(let relative):
        var components = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute],
          from: Date()
        )
        components.hour = relative.time.hour
        components.minute = relative.time.minute
        return Calendar.current.date(from: components)
      @unknown default:
        return nil
    }
  }
}

@available(iOS 26.0, *)
extension Alarm where Metadata == NeverMetadata {
    func toDictionary() -> [String: Any]? {
        var dict: [String: Any] = [:]
        dict["id"] = self.id.uuidString
        if let title = self.attributes.presentation.alert?.title {
            dict["label"] = title.key
        }

        var scheduleDict: [String: Any] = [:]
        switch self.schedule {
        case .fixed(let date):
            scheduleDict["type"] = "fixed"
            scheduleDict["timestamp"] = date.timeIntervalSince1970 * 1000
        case .relative(let relativeSchedule):
            scheduleDict["type"] = "relative"
            scheduleDict["hour"] = relativeSchedule.time.hour
            scheduleDict["minute"] = relativeSchedule.time.minute
        // Note: weekday recurrence is not available from AlarmKit's public API.
        case .countdown:
            scheduleDict["type"] = "countdown"
        @unknown default:
            return nil
        }
        dict["schedule"] = scheduleDict

        switch self.state {
        case .scheduled:
            dict["state"] = "scheduled"
        case .ringing:
            dict["state"] = "ringing"
        case .snoozed:
            dict["state"] = "snoozed"
        case .stopped:
            dict["state"] = "stopped"
        case .paused:
            dict["state"] = "paused"
        @unknown default:
            dict["state"] = "unknown"
        }
        return dict
    }
} 