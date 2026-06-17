import Flutter
import AlarmKit

@available(iOS 26.0, *)
class AlarmUpdateStreamHandler: NSObject, FlutterStreamHandler {
    private var streamTask: Task<Void, Never>?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Cancel any existing subscription so a re-listen never orphans a Task.
        streamTask?.cancel()
        // `previousAlarms` is kept local to this subscription so there is no
        // mutable state shared between the platform thread and this Task.
        streamTask = Task {
            var previousAlarms: Set<UUID> = []
            for await alarms in AlarmManager.shared.alarmUpdates {
                if Task.isCancelled { break }
                let currentAlarmIds = Set(alarms.map { $0.id })

                // Find added alarms
                let addedAlarms = currentAlarmIds.subtracting(previousAlarms)
                for alarmId in addedAlarms {
                    if let alarm = alarms.first(where: { $0.id == alarmId }) {
                        var eventData: [String: Any] = [:]
                        eventData["id"] = alarm.id.uuidString
                        eventData["event"] = "add"
                        eventData["alarm"] = alarm.toDictionary()
                        DispatchQueue.main.async { events(eventData) }
                    }
                }

                // Find removed alarms
                let removedAlarmIds = previousAlarms.subtracting(currentAlarmIds)
                for alarmId in removedAlarmIds {
                    var eventData: [String: Any] = [:]
                    eventData["id"] = alarmId.uuidString
                    eventData["event"] = "remove"
                    DispatchQueue.main.async { events(eventData) }
                }

                // Find updated alarms (exist in both sets, state may have changed)
                let existingAlarms = currentAlarmIds.intersection(previousAlarms)
                for alarmId in existingAlarms {
                    if let alarm = alarms.first(where: { $0.id == alarmId }) {
                        var eventData: [String: Any] = [:]
                        eventData["id"] = alarm.id.uuidString
                        eventData["event"] = "update"
                        eventData["alarm"] = alarm.toDictionary()
                        DispatchQueue.main.async { events(eventData) }
                    }
                }

                previousAlarms = currentAlarmIds
            }
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        streamTask?.cancel()
        streamTask = nil
        return nil
    }
}
