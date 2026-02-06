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

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
        message: "Invalid arguments",
        details: nil
      ))
      return nil
    }
    return args
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
    
    NSLog("🔊 resolveSoundAsset called with assetPath: \(assetPath)")

    // 1. Get the filename from the asset path (e.g., "assets/marimba.caf" -> "marimba.caf")
    let fileName = URL(fileURLWithPath: assetPath).lastPathComponent
    
    // 2. Define the target URL in Library/Sounds
    let fileManager = FileManager.default
    guard let libraryUrl = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
        NSLog("❌ ERROR: Could not find Library directory")
        return .default
    }
    let soundsUrl = libraryUrl.appendingPathComponent("Sounds")
    let destinationUrl = soundsUrl.appendingPathComponent(fileName)

    // 3. Copy the file if it's not already there
    if !fileManager.fileExists(atPath: destinationUrl.path) {
        // Check if registrar is initialized
        if FlutterAlarmkitPlugin.registrar == nil {
            NSLog("❌ ERROR: FlutterAlarmkitPlugin.registrar is nil!")
            return .default
        }

        // Look up the actual path in the Flutter assets
        guard let key = FlutterAlarmkitPlugin.registrar?.lookupKey(forAsset: assetPath),
              let sourcePath = Bundle.main.path(forResource: key, ofType: nil) else {
            NSLog("❌ Could not find asset '\(assetPath)' in bundle")
            return .default
        }
        
        do {
            // Create Library/Sounds directory if needed
            try fileManager.createDirectory(at: soundsUrl, withIntermediateDirectories: true)
            
            // Copy the file
            try fileManager.copyItem(at: URL(fileURLWithPath: sourcePath), to: destinationUrl)
            NSLog("✅ Copied sound to Library/Sounds: \(destinationUrl.path)")
        } catch {
            NSLog("❌ Failed to copy sound: \(error)")
            return .default
      }
    } else {
        NSLog("✅ Sound already exists in Library/Sounds: \(destinationUrl.path)")
    }

    // 4. Return just the filename. 
    // The system automatically looks in the main bundle and Library/Sounds.
    NSLog("📦 Returning .named(\(fileName))")
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
    guard let args = parseArgs(call, result: result),
          let timestampMs = args["timestamp"] as? Double else { return }

    let label = parseLabel(from: args)
    let date = Date(timeIntervalSince1970: timestampMs / 1000)

    let alertContent = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: label),
      stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.circle")
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

    // 7. Schedule and return the UUID string
    do {
      let alarm = try await manager.schedule(
        id: UUID(),
        configuration: alarmConfiguration
      )
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
    guard let args = parseArgs(call, result: result),
          let preSec = args["countdownDurationInSeconds"] as? Int,
          let postSec = args["repeatDurationInSeconds"] as? Int else { return }

    let label = parseLabel(from: args)
    let countdownDuration = Alarm.CountdownDuration(preAlert: TimeInterval(preSec), postAlert: TimeInterval(postSec))

    let stopButton = AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle")
    let repeatButton = AlarmButton(text: "Repeat", textColor: .white, systemImageName: "repeat.circle")
    let pauseButton = AlarmButton(text: "Pause", textColor: .green, systemImageName: "pause.circle")
    let resumeButton = AlarmButton(text: "Resume", textColor: .green, systemImageName: "play.circle")

    let presentation = AlarmPresentation(
      alert: AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: label),
        stopButton: stopButton,
        secondaryButton: repeatButton,
        secondaryButtonBehavior: .countdown
      ),
      countdown: AlarmPresentation.Countdown(
        title: LocalizedStringResource(stringLiteral: label),
        pauseButton: pauseButton
      ),
      paused: AlarmPresentation.Paused(
        title: LocalizedStringResource(stringLiteral: label),
        resumeButton: resumeButton
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

    // 7. Schedule and return the UUID string
    do {
      let alarm = try await manager.schedule(
        id: UUID(),
        configuration: alarmConfiguration
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
    guard let args = parseArgs(call, result: result),
          let mask = args["weekdayMask"] as? Int,
          let hour = args["hour"] as? Int,
          let minute = args["minute"] as? Int
    else { return }

    // 3. Decode bitmask into weekdays
    let weekdays = decodeWeekdays(from: mask)

    // 4. Build the weekly schedule
    let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
    let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
    let schedule = Alarm.Schedule.Relative(time: time, repeats: recurrence)

    // 5. Build presentation UI
    let label = parseLabel(from: args)
    let presentation = AlarmPresentation(
      alert: AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: label),
        stopButton: AlarmButton(
          text: "Stop",
          textColor: .white,
          systemImageName: "stop.circle"
        )
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
    guard let alarmId = call.arguments as? String else { return }

    do {
      try manager.cancel(id: UUID(uuidString: alarmId)!)
      result(true)
    } catch {
      result(FlutterError(
        code: "CANCEL_ERROR",
        message: "Failed to cancel alarm \(alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  private func countdownAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared
    guard let alarmId = call.arguments as? String else { return }

    do {
      try manager.countdown(id: UUID(uuidString: alarmId)!)
      result(true)
    } catch {
      result(FlutterError(
        code: "COUNTDOWN_ERROR",
        message: "Failed to countdown alarm \(alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  private func pauseAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared
    guard let alarmId = call.arguments as? String else { return }

    do {
      try manager.pause(id: UUID(uuidString: alarmId)!)
      result(true)
    } catch {
      result(FlutterError(
        code: "PAUSE_ERROR",
        message: "Failed to pause alarm \(alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  private func resumeAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared
    guard let alarmId = call.arguments as? String else { return }

    do {
      try manager.resume(id: UUID(uuidString: alarmId)!)
      result(true)
    } catch {
      result(FlutterError(
        code: "RESUME_ERROR",
        message: "Failed to resume alarm \(alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }


  private func stopAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared
    guard let alarmId = call.arguments as? String else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid arguments for stopAlarm",
        details: nil
      ))
      return
    }

    do {
      try manager.stop(id: UUID(uuidString: alarmId)!)
      result(true)
    } catch {
      result(FlutterError(
        code: "STOP_ERROR",
        message: "Failed to stop alarm \(alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }
}

