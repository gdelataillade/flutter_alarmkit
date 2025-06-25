import Flutter
import AlarmKit

@available(iOS 26.0, *)
class AlarmUpdateStreamHandler: NSObject, FlutterStreamHandler {
    private var streamTask: Task<Void, Never>?
    private var previousAlarms: Set<UUID> = []

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.streamTask = Task {
            for await alarms in AlarmManager.shared.alarmUpdates {
                let currentAlarmIds = Set(alarms.map { $0.id })
                
                // Find added alarms
                let addedAlarms = currentAlarmIds.subtracting(previousAlarms)
                for alarmId in addedAlarms {
                    if let alarm = alarms.first(where: { $0.id == alarmId }) {
                        var eventData: [String: Any] = [:]
                        eventData["id"] = alarm.id.uuidString
                        eventData["event"] = "add"
                        eventData["alarm"] = alarm.toDictionary()
                        
                        DispatchQueue.main.async {
                            events(eventData)
                        }
                    }
                }
                
                // Find removed alarms
                let removedAlarmIds = previousAlarms.subtracting(currentAlarmIds)
                for alarmId in removedAlarmIds {
                    var eventData: [String: Any] = [:]
                    eventData["id"] = alarmId.uuidString
                    eventData["event"] = "remove"
                    
                    DispatchQueue.main.async {
                        events(eventData)
                    }
                }
                
                // Find updated alarms (alarms that exist in both sets but may have changed state)
                let existingAlarms = currentAlarmIds.intersection(previousAlarms)
                for alarmId in existingAlarms {
                    if let alarm = alarms.first(where: { $0.id == alarmId }) {
                        var eventData: [String: Any] = [:]
                        eventData["id"] = alarm.id.uuidString
                        eventData["event"] = "update"
                        eventData["alarm"] = alarm.toDictionary()
                        
                        DispatchQueue.main.async {
                            events(eventData)
                        }
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