import Flutter
import ActivityKit
import UIKit
import AlarmKit
import SwiftUI

@available(iOS 26.0, *)
public class FlutterAlarmkitPlugin: NSObject, FlutterPlugin {
  // Store the registrar as a static property
  private static var registrar: FlutterPluginRegistrar?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Store the registrar for asset lookup
    self.registrar = registrar
    
    let channel = FlutterMethodChannel(
      name: "flutter_alarmkit",
      binaryMessenger: registrar.messenger()
    )
    let instance = FlutterAlarmkitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventChannel = FlutterEventChannel(name: "flutter_alarmkit/events", binaryMessenger: registrar.messenger())
    let streamHandler = AlarmUpdateStreamHandler()
    eventChannel.setStreamHandler(streamHandler)
  }

  public func handle(_ call: FlutterMethodCall, result rawResult: @escaping FlutterResult) {
    // Flutter requires channel replies on the platform (main) thread. The async
    // helpers below resume on a background executor, so funnel every reply back
    // to main before invoking the original callback.
    let result: FlutterResult = { value in
      if Thread.isMainThread {
        rawResult(value)
      } else {
        DispatchQueue.main.async { rawResult(value) }
      }
    }
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "requestAuthorization":
      Task { await self.requestAuthorization(result: result) }

    case "getAuthorizationState":
      Task { await self.getAuthorizationState(result: result) }

    case "scheduleOneShotAlarm":
      Task { await self.scheduleOneShotAlarm(call: call, result: result) }

    case "setCountdownAlarm":
      Task { await self.setCountdownAlarm(call: call, result: result) }

    case "scheduleRecurrentAlarm":
      Task { await self.scheduleRecurrentAlarm(call: call, result: result) }

    case "getAlarms":
      Task { await self.getAlarms(result: result) }

    case "cancelAlarm":
      Task { await self.cancelAlarm(call: call, result: result) }

    case "countdownAlarm":
      Task { await self.countdownAlarm(call: call, result: result) }

    case "pauseAlarm":
      Task { await self.pauseAlarm(call: call, result: result) }

    case "resumeAlarm":
      Task { await self.resumeAlarm(call: call, result: result) }

    case "stopAlarm":
      Task { await self.stopAlarm(call: call, result: result) }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Helpers

  /// Convert a hex string "#RRGGBB" or "RRGGBB" into UIColor
  private func color(from hex: String) -> UIColor? {
    var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if hexString.hasPrefix("#") {
      hexString.removeFirst()
    }
    guard hexString.count == 6,
          let intVal = Int(hexString, radix: 16)
    else { return nil }

    let red   = CGFloat((intVal >> 16) & 0xFF) / 255.0
    let green = CGFloat((intVal >> 8)  & 0xFF) / 255.0
    let blue  = CGFloat(intVal         & 0xFF) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
  }

  // MARK: - App Group

  static let appGroupId = "group.flutter-alarmkit"

  // MARK: - Button Config

  private struct ButtonConfig {
    let text: String
    let textColor: Color
    let systemImageName: String
    let tintColor: Color

    func toAlarmButton() -> AlarmButton {
      return AlarmButton(text: LocalizedStringResource(stringLiteral: text), textColor: textColor, systemImageName: systemImageName)
    }

    var tintHexString: String {
      let uiColor = UIColor(tintColor)
      var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
      uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
      return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
  }

  private static let defaultStopButton = ButtonConfig(
    text: "Stop", textColor: .white, systemImageName: "stop.circle", tintColor: .red
  )
  private static let defaultCountdownStopButton = ButtonConfig(
    text: "Done", textColor: .white, systemImageName: "stop.circle", tintColor: .red
  )
  private static let defaultPauseButton = ButtonConfig(
    text: "Pause", textColor: .green, systemImageName: "pause.circle", tintColor: .orange
  )
  private static let defaultResumeButton = ButtonConfig(
    text: "Resume", textColor: .green, systemImageName: "play.circle", tintColor: .green
  )
  private static let defaultRepeatButton = ButtonConfig(
    text: "Repeat", textColor: .white, systemImageName: "repeat.circle", tintColor: .blue
  )

  private func parseButtonConfig(
    from dict: [String: Any]?,
    defaults: ButtonConfig
  ) -> ButtonConfig {
    guard let dict = dict else { return defaults }
    let text = dict["text"] as? String ?? defaults.text
    let icon = dict["icon"] as? String ?? defaults.systemImageName
    let textColor: Color = {
      if let hex = dict["textColor"] as? String, let uiColor = color(from: hex) {
        return Color(uiColor: uiColor)
      }
      return defaults.textColor
    }()
    let tintColor: Color = {
      if let hex = dict["tintColor"] as? String, let uiColor = color(from: hex) {
        return Color(uiColor: uiColor)
      }
      return defaults.tintColor
    }()
    return ButtonConfig(text: text, textColor: textColor, systemImageName: icon, tintColor: tintColor)
  }

  private func storeButtonTints(alarmId: String, stop: ButtonConfig, pause: ButtonConfig? = nil, resume: ButtonConfig? = nil) {
    guard let defaults = UserDefaults(suiteName: FlutterAlarmkitPlugin.appGroupId) else {
      NSLog("⚠️ Could not access App Group UserDefaults (\(FlutterAlarmkitPlugin.appGroupId)). Button tint colors will use defaults.")
      return
    }
    var tints: [String: String] = [
      "stopTint": stop.tintHexString,
    ]
    if let pause = pause {
      tints["pauseTint"] = pause.tintHexString
    }
    if let resume = resume {
      tints["resumeTint"] = resume.tintHexString
    }
    defaults.set(tints, forKey: "alarm_tints_\(alarmId)")
  }

  // MARK: - Authorization

  private func requestAuthorization(result: @escaping FlutterResult) async {
    do {
      let status = try await AlarmManager.shared.requestAuthorization()
      switch status {
        case .authorized:
          result(true)
        case .denied, .notDetermined:
          result(false)
        @unknown default:
          result(false)
      }
    } catch {
      result(FlutterError(
        code: "AUTH_ERROR",
        message: "Failed to request alarm authorization: \(error)",
        details: nil
      ))
    }
  }

  private func getAuthorizationState(result: @escaping FlutterResult) async {
    let manager = AlarmManager.shared
    switch manager.authorizationState {
    case .notDetermined:
      result(0)
    case .denied:
      result(2)
    case .authorized:
      result(3)
    @unknown default:
      result(0)
    }
  }

  // MARK: - Private Helpers

  private func ensureAuthorized(result: @escaping FlutterResult) async -> Bool {
    let manager = AlarmManager.shared
    switch manager.authorizationState {
    case .notDetermined:
      do {
        let state = try await manager.requestAuthorization()
        guard state == .authorized else {
          result(FlutterError(
            code: "NOT_AUTHORIZED",
            message: "AlarmKit authorization denied by user",
            details: nil
          ))
          return false
        }
      } catch {
        result(FlutterError(
          code: "AUTH_ERROR",
          message: "Failed to request alarm authorization: \(error)",
          details: nil
        ))
        return false
      }
    case .denied:
      result(FlutterError(
        code: "NOT_AUTHORIZED",
        message: "AlarmKit authorization denied or restricted. Please enable in Settings.",
        details: nil
      ))
      return false
    case .authorized:
      return true
    @unknown default:
      result(FlutterError(
        code: "UNKNOWN_AUTH_STATE",
        message: "Unknown authorization state: \(manager.authorizationState)",
        details: nil
      ))
      return false
    }
    return true
  }

  private func parseArgs(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> [String: Any]? {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid arguments: expected a dictionary payload.",
        details: nil
      ))
      return nil
    }
    return args
  }

  private func parseAlarmUUID(
    from call: FlutterMethodCall,
    methodName: String,
    result: @escaping FlutterResult
  ) -> (alarmId: String, uuid: UUID)? {
    guard let alarmId = call.arguments as? String, !alarmId.isEmpty else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid arguments for \(methodName): expected non-empty alarmId string.",
        details: nil
      ))
      return nil
    }

    guard let uuid = UUID(uuidString: alarmId) else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid alarmId for \(methodName): expected UUID string.",
        details: nil
      ))
      return nil
    }

    return (alarmId, uuid)
  }

  private func parseLabel(from args: [String: Any]) -> String {
    return args["label"] as? String ?? "Alarm"
  }

  private func parseTintColor(from args: [String: Any]) -> Color {
    let defaultTint = UIColor.blue
    if let hex = args["tintColor"] as? String,
       let uiColor = color(from: hex) {
      return Color(uiColor: uiColor)
    }
    return Color(uiColor: defaultTint)
  }

  private func parseSoundPath(from args: [String: Any]) -> String? {
    return args["soundPath"] as? String
  }

  private func resolveSoundAsset(_ assetPath: String?) -> AlertConfiguration.AlertSound {
    guard let assetPath = assetPath, !assetPath.isEmpty else {
      return .default
    }

    // 1. Get the filename from the asset path (e.g., "assets/marimba.caf" -> "marimba.caf")
    let fileName = URL(fileURLWithPath: assetPath).lastPathComponent
    
    // 2. Define the target URL in Library/Sounds
    let fileManager = FileManager.default
    guard let libraryUrl = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
        NSLog("[flutter_alarmkit] Could not find Library directory; using default sound")
        return .default
    }
    let soundsUrl = libraryUrl.appendingPathComponent("Sounds")
    let destinationUrl = soundsUrl.appendingPathComponent(fileName)

    // 3. Copy the file if it's not already there
    if !fileManager.fileExists(atPath: destinationUrl.path) {
        // Check if registrar is initialized
        if FlutterAlarmkitPlugin.registrar == nil {
            NSLog("[flutter_alarmkit] Plugin registrar unavailable; using default sound")
            return .default
        }

        // Look up the actual path in the Flutter assets
        guard let key = FlutterAlarmkitPlugin.registrar?.lookupKey(forAsset: assetPath),
              let sourcePath = Bundle.main.path(forResource: key, ofType: nil) else {
            NSLog("[flutter_alarmkit] Could not find sound asset '\(assetPath)' in bundle; using default sound")
            return .default
        }

        do {
            // Create Library/Sounds directory if needed
            try fileManager.createDirectory(at: soundsUrl, withIntermediateDirectories: true)

            // Copy the file
            try fileManager.copyItem(at: URL(fileURLWithPath: sourcePath), to: destinationUrl)
        } catch {
            NSLog("[flutter_alarmkit] Failed to copy sound asset; using default sound: \(error)")
            return .default
      }
    }

    // 4. Return just the filename.
    // The system automatically looks in the main bundle and Library/Sounds.
    return .named(fileName)
  }

  private func decodeWeekdays(from mask: Int) -> [Locale.Weekday] {
    var weekdays: [Locale.Weekday] = []
    if mask & (1 << 0) != 0 { weekdays.append(.monday) }
    if mask & (1 << 1) != 0 { weekdays.append(.tuesday) }
    if mask & (1 << 2) != 0 { weekdays.append(.wednesday) }
    if mask & (1 << 3) != 0 { weekdays.append(.thursday) }
    if mask & (1 << 4) != 0 { weekdays.append(.friday) }
    if mask & (1 << 5) != 0 { weekdays.append(.saturday) }
    if mask & (1 << 6) != 0 { weekdays.append(.sunday) }
    return weekdays
  }

  // MARK: - Manage alarms methods

  private func scheduleOneShotAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared

    // 1. Ensure authorization
    guard await ensureAuthorized(result: result) else { return }

    // 2. Parse arguments
    guard let args = parseArgs(call, result: result) else { return }
    guard let timestampMs = args["timestamp"] as? Double else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid timestamp: expected a number in milliseconds.",
        details: nil
      ))
      return
    }
    guard timestampMs.isFinite else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid timestamp: expected a finite number in milliseconds.",
        details: nil
      ))
      return
    }

    let label = parseLabel(from: args)
    let date = Date(timeIntervalSince1970: timestampMs / 1000)
    let uiConfigDict = args["uiConfig"] as? [String: Any]

    let stopConfig = parseButtonConfig(
      from: uiConfigDict?["stopButton"] as? [String: Any],
      defaults: FlutterAlarmkitPlugin.defaultStopButton
    )

    let alertContent = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: label),
      stopButton: stopConfig.toAlarmButton()
    )

    let tintColor = parseTintColor(from: args)

    let presentation = AlarmPresentation(alert: alertContent)

    let attributes = AlarmAttributes<NeverMetadata>(
      presentation: presentation,
      tintColor: tintColor
    )

    let soundPath = parseSoundPath(from: args)
    let alarmConfiguration = AlarmManager.AlarmConfiguration<NeverMetadata>(
        schedule: .fixed(date),
        attributes: attributes,
        sound: resolveSoundAsset(soundPath),
    )

    do {
      let alarm = try await manager.schedule(
        id: UUID(),
        configuration: alarmConfiguration
      )
      storeButtonTints(alarmId: alarm.id.uuidString, stop: stopConfig)
      result(alarm.id.uuidString)
    } catch {
      result(FlutterError(
        code: "SCHEDULE_ERROR",
        message: "Failed to schedule alarm: \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  private func setCountdownAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared

    // 1. Ensure authorization
    guard await ensureAuthorized(result: result) else { return }

    // 2. Parse arguments
    guard let args = parseArgs(call, result: result) else { return }
    guard let preSec = args["countdownDurationInSeconds"] as? Int else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid countdownDurationInSeconds: expected an integer.",
        details: nil
      ))
      return
    }
    guard let postSec = args["repeatDurationInSeconds"] as? Int else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid repeatDurationInSeconds: expected an integer.",
        details: nil
      ))
      return
    }
    guard preSec > 0 else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid countdownDurationInSeconds: expected a value greater than 0.",
        details: nil
      ))
      return
    }
    guard postSec >= 0 else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid repeatDurationInSeconds: expected a value greater than or equal to 0.",
        details: nil
      ))
      return
    }

    let label = parseLabel(from: args)
    let countdownDuration = Alarm.CountdownDuration(preAlert: TimeInterval(preSec), postAlert: TimeInterval(postSec))
    let uiConfigDict = args["uiConfig"] as? [String: Any]

    let stopConfig = parseButtonConfig(
      from: uiConfigDict?["stopButton"] as? [String: Any],
      defaults: FlutterAlarmkitPlugin.defaultCountdownStopButton
    )
    let repeatConfig = parseButtonConfig(
      from: uiConfigDict?["repeatButton"] as? [String: Any],
      defaults: FlutterAlarmkitPlugin.defaultRepeatButton
    )
    let pauseConfig = parseButtonConfig(
      from: uiConfigDict?["pauseButton"] as? [String: Any],
      defaults: FlutterAlarmkitPlugin.defaultPauseButton
    )
    let resumeConfig = parseButtonConfig(
      from: uiConfigDict?["resumeButton"] as? [String: Any],
      defaults: FlutterAlarmkitPlugin.defaultResumeButton
    )

    let countdownTitle = uiConfigDict?["countdownTitle"] as? String ?? label
    let pausedTitle = uiConfigDict?["pausedTitle"] as? String ?? label

    let presentation = AlarmPresentation(
      alert: AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: label),
        stopButton: stopConfig.toAlarmButton(),
        secondaryButton: repeatConfig.toAlarmButton(),
        secondaryButtonBehavior: .countdown
      ),
      countdown: AlarmPresentation.Countdown(
        title: LocalizedStringResource(stringLiteral: countdownTitle),
        pauseButton: pauseConfig.toAlarmButton()
      ),
      paused: AlarmPresentation.Paused(
        title: LocalizedStringResource(stringLiteral: pausedTitle),
        resumeButton: resumeConfig.toAlarmButton()
      )
    )
    let tintColor = parseTintColor(from: args)
    let attributes = AlarmAttributes<NeverMetadata>(
      presentation: presentation,
      tintColor: tintColor
    )
    let soundPath = parseSoundPath(from: args)
    let alarmConfiguration = AlarmManager
      .AlarmConfiguration<NeverMetadata>(
        countdownDuration: countdownDuration,
        attributes: attributes,
        sound: resolveSoundAsset(soundPath),
      )

    do {
      let alarm = try await manager.schedule(
        id: UUID(),
        configuration: alarmConfiguration
      )
      storeButtonTints(
        alarmId: alarm.id.uuidString,
        stop: stopConfig,
        pause: pauseConfig,
        resume: resumeConfig
      )
      result(alarm.id.uuidString)
    } catch {
      result(FlutterError(
        code: "SCHEDULE_ERROR",
        message: "Failed to schedule countdown alarm: \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  private func scheduleRecurrentAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared

    // 1. Make sure we're allowed to schedule
    guard await ensureAuthorized(result: result) else { return }

    // 2. Parse args
    guard let args = parseArgs(call, result: result) else { return }
    guard let mask = args["weekdayMask"] as? Int else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid weekdayMask: expected an integer bitmask.",
        details: nil
      ))
      return
    }
    guard let hour = args["hour"] as? Int else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid hour: expected an integer between 0 and 23.",
        details: nil
      ))
      return
    }
    guard let minute = args["minute"] as? Int else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid minute: expected an integer between 0 and 59.",
        details: nil
      ))
      return
    }
    guard mask != 0 else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid weekdayMask: expected at least one selected weekday.",
        details: nil
      ))
      return
    }
    guard (0...23).contains(hour) else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid hour: expected a value between 0 and 23.",
        details: nil
      ))
      return
    }
    guard (0...59).contains(minute) else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid minute: expected a value between 0 and 59.",
        details: nil
      ))
      return
    }

    // 3. Decode bitmask into weekdays
    let weekdays = decodeWeekdays(from: mask)

    // 4. Build the weekly schedule
    let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
    let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
    let schedule = Alarm.Schedule.Relative(time: time, repeats: recurrence)

    // 5. Build presentation UI
    let label = parseLabel(from: args)
    let uiConfigDict = args["uiConfig"] as? [String: Any]

    let stopConfig = parseButtonConfig(
      from: uiConfigDict?["stopButton"] as? [String: Any],
      defaults: FlutterAlarmkitPlugin.defaultStopButton
    )

    let presentation = AlarmPresentation(
      alert: AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: label),
        stopButton: stopConfig.toAlarmButton()
      )
    )
    let tintColor = parseTintColor(from: args)
    let attributes = AlarmAttributes<NeverMetadata>(
      presentation: presentation,
      tintColor: tintColor
    )

    // 6. Configure and schedule
    let soundPath = parseSoundPath(from: args)
    let config = AlarmManager
      .AlarmConfiguration<NeverMetadata>(
        schedule: .relative(schedule),
        attributes: attributes,
        sound: resolveSoundAsset(soundPath),
      )

    do {
      let alarm = try await manager.schedule(
        id: UUID(), configuration: config
      )
      storeButtonTints(alarmId: alarm.id.uuidString, stop: stopConfig)
      result(alarm.id.uuidString)
    } catch {
      result(FlutterError(
        code: "SCHEDULE_ERROR",
        message: "Failed to schedule recurrent alarm: \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  private func getAlarms(result: @escaping FlutterResult) async {
    let manager = AlarmManager.shared
    do {
        let alarms = try manager.alarms
        let alarmsData = alarms.compactMap { $0.toDictionary() }
        result(alarmsData)
    } catch {
        result(FlutterError(
            code: "GET_ALARMS_ERROR",
            message: "Failed to get alarms: \(error.localizedDescription)",
            details: nil
        ))
    }
  }

  private func cancelAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared
    guard let parsed = parseAlarmUUID(
      from: call,
      methodName: "cancelAlarm",
      result: result
    ) else { return }

    do {
      try manager.cancel(id: parsed.uuid)
      result(true)
    } catch {
      result(FlutterError(
        code: "CANCEL_ERROR",
        message: "Failed to cancel alarm \(parsed.alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  private func countdownAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared
    guard let parsed = parseAlarmUUID(
      from: call,
      methodName: "countdownAlarm",
      result: result
    ) else { return }

    do {
      try manager.countdown(id: parsed.uuid)
      result(true)
    } catch {
      result(FlutterError(
        code: "COUNTDOWN_ERROR",
        message: "Failed to countdown alarm \(parsed.alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  private func pauseAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared
    guard let parsed = parseAlarmUUID(
      from: call,
      methodName: "pauseAlarm",
      result: result
    ) else { return }

    do {
      try manager.pause(id: parsed.uuid)
      result(true)
    } catch {
      result(FlutterError(
        code: "PAUSE_ERROR",
        message: "Failed to pause alarm \(parsed.alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  private func resumeAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared
    guard let parsed = parseAlarmUUID(
      from: call,
      methodName: "resumeAlarm",
      result: result
    ) else { return }

    do {
      try manager.resume(id: parsed.uuid)
      result(true)
    } catch {
      result(FlutterError(
        code: "RESUME_ERROR",
        message: "Failed to resume alarm \(parsed.alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }


  private func stopAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared
    guard let parsed = parseAlarmUUID(
      from: call,
      methodName: "stopAlarm",
      result: result
    ) else { return }

    do {
      try manager.stop(id: parsed.uuid)
      result(true)
    } catch {
      result(FlutterError(
        code: "STOP_ERROR",
        message: "Failed to stop alarm \(parsed.alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }
}
