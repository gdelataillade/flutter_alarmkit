import Foundation
import AlarmKit

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