import Flutter
import AlarmKit

@available(iOS 26.0, *)
class AlarmUpdateStreamHandler: NSObject, FlutterStreamHandler {
    private var streamTask: Task<Void, Never>?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Cancel any existing subscription so a re-listen never orphans a Task.
        streamTask?.cancel()
        // `previous` is kept local to this subscription so there is no mutable
        // state shared between the platform thread and this Task. It maps each
        // alarm id to a change-signature so we only emit `update` events when an
        // alarm's state, schedule, or countdown actually changed.
        streamTask = Task {
            var previous: [UUID: String] = [:]
            for await alarms in AlarmManager.shared.alarmUpdates {
                if Task.isCancelled { break }

                // Serialize once per snapshot, reusing the dict for both the
                // change-signature and the emitted payload.
                var currentDicts: [UUID: [String: Any]] = [:]
                var currentSignatures: [UUID: String] = [:]
                for alarm in alarms {
                    let dict = alarm.toDictionary()
                    currentDicts[alarm.id] = dict
                    currentSignatures[alarm.id] = AlarmUpdateStreamHandler.signature(from: dict)
                }

                let currentIds = Set(currentDicts.keys)
                let previousIds = Set(previous.keys)

                // Added alarms.
                for id in currentIds.subtracting(previousIds) {
                    if let dict = currentDicts[id] {
                        AlarmUpdateStreamHandler.emit(
                            ["id": id.uuidString, "event": "add", "alarm": dict],
                            to: events
                        )
                    }
                }

                // Removed alarms — also clean up persisted metadata, since the
                // system can remove an alarm without an explicit cancel call.
                for id in previousIds.subtracting(currentIds) {
                    AlarmkitPluginImpl.removeAlarmPersistence(id.uuidString)
                    AlarmUpdateStreamHandler.emit(
                        ["id": id.uuidString, "event": "remove"],
                        to: events
                    )
                }

                // Updated alarms — only when the signature genuinely changed.
                for id in currentIds.intersection(previousIds)
                where previous[id] != currentSignatures[id] {
                    if let dict = currentDicts[id] {
                        AlarmUpdateStreamHandler.emit(
                            ["id": id.uuidString, "event": "update", "alarm": dict],
                            to: events
                        )
                    }
                }

                previous = currentSignatures
            }
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        streamTask?.cancel()
        streamTask = nil
        return nil
    }

    /// A fingerprint of the change-relevant fields (state, schedule, countdown
    /// duration). Label and tint are intentionally excluded: they are immutable
    /// for a given alarm and must not trigger spurious `update` events.
    private static func signature(from dict: [String: Any]) -> String {
        let state = dict["state"] as? String ?? ""
        var schedule = "none"
        if let s = dict["schedule"] as? [String: Any] {
            let type = s["type"] as? String ?? ""
            schedule = "\(type)|\(s["timestamp"] ?? "")|\(s["hour"] ?? "")|\(s["minute"] ?? "")|\(s["weekdayMask"] ?? "")"
        }
        var countdown = "none"
        if let c = dict["countdownDuration"] as? [String: Any] {
            countdown = "\(c["preAlert"] ?? "")|\(c["postAlert"] ?? "")"
        }
        return "\(state)#\(schedule)#\(countdown)"
    }

    private static func emit(_ payload: [String: Any], to events: @escaping FlutterEventSink) {
        DispatchQueue.main.async { events(payload) }
    }
}
