import Flutter
import ActivityKit
import UIKit
import AlarmKit
import SwiftUI

/// Public registration entry point, callable on any iOS version.
///
/// The generated plugin registrant invokes `register(with:)` unconditionally,
/// so this shell must NOT be `@available`-gated — otherwise the call traps on
/// devices below the deployment floor. AlarmKit and the real implementation
/// (`AlarmkitPluginImpl`) require iOS 26, so on older systems we register a
/// method-call handler that fails every call with a clear `UNSUPPORTED_VERSION`
/// error instead of touching an unavailable symbol.
public class FlutterAlarmkitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    if #available(iOS 26.0, *) {
      AlarmkitPluginImpl.register(with: registrar)
    } else {
      let channel = FlutterMethodChannel(
        name: "flutter_alarmkit",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { _, result in
        result(
          FlutterError(
            code: "UNSUPPORTED_VERSION",
            message: "AlarmKit is only available on iOS 26.0 and above",
            details: nil
          )
        )
      }

      // Also fail the alarm-updates stream with the same error, so listening to
      // FlutterAlarmkit().alarmUpdates() on iOS < 26 surfaces UNSUPPORTED_VERSION
      // rather than a missing-handler error.
      let eventChannel = FlutterEventChannel(
        name: "flutter_alarmkit/events",
        binaryMessenger: registrar.messenger()
      )
      eventChannel.setStreamHandler(UnsupportedVersionStreamHandler())
    }
  }
}

/// Stream handler used on iOS < 26: fails every listen with `UNSUPPORTED_VERSION`
/// so the alarm-updates stream matches the method channel's behavior. Kept
/// outside the `@available` implementation so it is safe to instantiate on any
/// iOS version.
private class UnsupportedVersionStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    return FlutterError(
      code: "UNSUPPORTED_VERSION",
      message: "AlarmKit is only available on iOS 26.0 and above",
      details: nil
    )
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}

@available(iOS 26.0, *)
public class AlarmkitPluginImpl: NSObject, FlutterPlugin {
  // Store the registrar as a static property
  private static var registrar: FlutterPluginRegistrar?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Store the registrar for asset lookup
    self.registrar = registrar
    
    let channel = FlutterMethodChannel(
      name: "flutter_alarmkit",
      binaryMessenger: registrar.messenger()
    )
    let instance = AlarmkitPluginImpl()
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

    case "cancelAll":
      Task { await self.cancelAll(result: result) }

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

  /// Convert a SwiftUI `Color` into a `#RRGGBB` hex string.
  private func hexString(from color: Color) -> String {
    let uiColor = UIColor(color)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
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
    text: "Pause", textColor: .white, systemImageName: "pause.circle", tintColor: .orange
  )
  private static let defaultResumeButton = ButtonConfig(
    text: "Resume", textColor: .white, systemImageName: "play.circle", tintColor: .green
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

  private func storeButtonTints(alarmId: String, stop: ButtonConfig, pause: ButtonConfig? = nil, resume: ButtonConfig? = nil, repeatButton: ButtonConfig? = nil) {
    guard let defaults = UserDefaults(suiteName: AlarmkitPluginImpl.appGroupId) else {
      NSLog("⚠️ Could not access App Group UserDefaults (\(AlarmkitPluginImpl.appGroupId)). Button tint colors will use defaults.")
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
    if let repeatButton = repeatButton {
      tints["repeatTint"] = repeatButton.tintHexString
    }
    defaults.set(tints, forKey: "alarm_tints_\(alarmId)")
  }

  /// Persist the alarm's label and tint color in the App Group so they can be
  /// returned later — AlarmKit does not expose presentation back to the app.
  /// `createdAt` (epoch seconds) lets `getAlarms` prune orphans without racing
  /// an in-flight schedule.
  private func storeAlarmMeta(alarmId: String, label: String, tintColorHex: String, createdAt: TimeInterval, metadata: NeverMetadata? = nil) {
    guard let defaults = UserDefaults(suiteName: AlarmkitPluginImpl.appGroupId) else {
      NSLog("⚠️ Could not access App Group UserDefaults (\(AlarmkitPluginImpl.appGroupId)). Alarm label/tint will be unavailable from getAlarms().")
      return
    }
    var stored: [String: Any] = [
      "label": label,
      "tintColor": tintColorHex,
      "createdAt": createdAt,
    ]
    // Persist the displayable metadata as a nested dictionary so getAlarms()
    // can return it (AlarmKit does not expose attributes after scheduling).
    if let metadata = metadata {
      var metaDict: [String: String] = [:]
      if let icon = metadata.icon, !icon.isEmpty { metaDict["icon"] = icon }
      if let subtitle = metadata.subtitle, !subtitle.isEmpty { metaDict["subtitle"] = subtitle }
      if !metaDict.isEmpty { stored["metadata"] = metaDict }
    }
    defaults.set(stored, forKey: "alarm_meta_\(alarmId)")
  }

  /// Remove all persisted App Group state (meta + button tints) for an alarm.
  private func removeAlarmPersistence(_ alarmId: String) {
    AlarmkitPluginImpl.removeAlarmPersistence(alarmId)
  }

  /// Static variant of `removeAlarmPersistence`, usable from the alarm-updates
  /// stream handler (which has no plugin instance).
  static func removeAlarmPersistence(_ alarmId: String) {
    guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
    defaults.removeObject(forKey: "alarm_meta_\(alarmId)")
    defaults.removeObject(forKey: "alarm_tints_\(alarmId)")
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
      // Distinct sentinel so Dart maps this to AlarmAuthorizationState.unknown
      // rather than collapsing into notDetermined (0).
      result(-1)
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

  /// Parse the optional displayable metadata (icon + subtitle). Empty strings
  /// are treated as absent; returns nil when no field is set.
  private func parseMetadata(from args: [String: Any]) -> NeverMetadata? {
    guard let dict = args["metadata"] as? [String: Any] else { return nil }
    let icon = (dict["icon"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    let subtitle = (dict["subtitle"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    if icon == nil, subtitle == nil { return nil }
    return NeverMetadata(icon: icon, subtitle: subtitle)
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
        if AlarmkitPluginImpl.registrar == nil {
            NSLog("[flutter_alarmkit] Plugin registrar unavailable; using default sound")
            return .default
        }

        // Look up the actual path in the Flutter assets
        guard let key = AlarmkitPluginImpl.registrar?.lookupKey(forAsset: assetPath),
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
      defaults: AlarmkitPluginImpl.defaultStopButton
    )

    let tintColor = parseTintColor(from: args)
    let id = UUID()

    let alertContent = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: label),
      stopButton: stopConfig.toAlarmButton()
    )
    let presentation = AlarmPresentation(alert: alertContent)

    let metadata = parseMetadata(from: args)
    let attributes = AlarmAttributes<NeverMetadata>(
      presentation: presentation,
      metadata: metadata,
      tintColor: tintColor
    )

    let soundPath = parseSoundPath(from: args)
    let alarmConfiguration = AlarmManager.AlarmConfiguration<NeverMetadata>(
      schedule: .fixed(date),
      attributes: attributes,
      sound: resolveSoundAsset(soundPath)
    )

    // Persist presentation metadata BEFORE scheduling so the alarm-updates
    // stream's initial `add` event already carries the label/tint, and roll it
    // back if scheduling fails.
    storeAlarmMeta(
      alarmId: id.uuidString,
      label: label,
      tintColorHex: hexString(from: tintColor),
      createdAt: Date().timeIntervalSince1970,
      metadata: metadata
    )
    storeButtonTints(alarmId: id.uuidString, stop: stopConfig)

    do {
      let alarm = try await manager.schedule(
        id: id,
        configuration: alarmConfiguration
      )
      result(alarm.id.uuidString)
    } catch {
      removeAlarmPersistence(id.uuidString)
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
    // A zero repeat duration means a non-repeating countdown: AlarmKit traps if
    // a `.countdown` secondary button is paired with a zero/absent postAlert,
    // so both must be omitted together.
    let repeats = postSec > 0
    let countdownDuration = Alarm.CountdownDuration(
      preAlert: TimeInterval(preSec),
      postAlert: repeats ? TimeInterval(postSec) : nil)
    let uiConfigDict = args["uiConfig"] as? [String: Any]

    let stopConfig = parseButtonConfig(
      from: uiConfigDict?["stopButton"] as? [String: Any],
      defaults: AlarmkitPluginImpl.defaultCountdownStopButton
    )
    let repeatConfig = parseButtonConfig(
      from: uiConfigDict?["repeatButton"] as? [String: Any],
      defaults: AlarmkitPluginImpl.defaultRepeatButton
    )
    let pauseConfig = parseButtonConfig(
      from: uiConfigDict?["pauseButton"] as? [String: Any],
      defaults: AlarmkitPluginImpl.defaultPauseButton
    )
    let resumeConfig = parseButtonConfig(
      from: uiConfigDict?["resumeButton"] as? [String: Any],
      defaults: AlarmkitPluginImpl.defaultResumeButton
    )

    let countdownTitle = uiConfigDict?["countdownTitle"] as? String ?? label
    let pausedTitle = uiConfigDict?["pausedTitle"] as? String ?? label

    let presentation = AlarmPresentation(
      alert: AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: label),
        stopButton: stopConfig.toAlarmButton(),
        secondaryButton: repeats ? repeatConfig.toAlarmButton() : nil,
        secondaryButtonBehavior: repeats ? .countdown : nil
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
    let metadata = parseMetadata(from: args)
    let attributes = AlarmAttributes<NeverMetadata>(
      presentation: presentation,
      metadata: metadata,
      tintColor: tintColor
    )
    let soundPath = parseSoundPath(from: args)
    let alarmConfiguration = AlarmManager
      .AlarmConfiguration<NeverMetadata>(
        countdownDuration: countdownDuration,
        attributes: attributes,
        sound: resolveSoundAsset(soundPath),
      )

    let id = UUID()
    storeAlarmMeta(
      alarmId: id.uuidString,
      label: label,
      tintColorHex: hexString(from: tintColor),
      createdAt: Date().timeIntervalSince1970,
      metadata: metadata
    )
    storeButtonTints(
      alarmId: id.uuidString,
      stop: stopConfig,
      pause: pauseConfig,
      resume: resumeConfig,
      repeatButton: repeatConfig
    )

    do {
      let alarm = try await manager.schedule(
        id: id,
        configuration: alarmConfiguration
      )
      result(alarm.id.uuidString)
    } catch {
      removeAlarmPersistence(id.uuidString)
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
    guard mask & ~0x7F == 0 else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid weekdayMask: expected weekday bits only (0...0x7F).",
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

    // 4. Build the relative schedule. An empty mask means "fire once" (.never);
    //    otherwise repeat weekly on the selected weekdays.
    let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
    let recurrence: Alarm.Schedule.Relative.Recurrence =
      weekdays.isEmpty ? .never : .weekly(weekdays)
    let schedule = Alarm.Schedule.Relative(time: time, repeats: recurrence)

    // 5. Build presentation UI
    let label = parseLabel(from: args)
    let uiConfigDict = args["uiConfig"] as? [String: Any]

    let stopConfig = parseButtonConfig(
      from: uiConfigDict?["stopButton"] as? [String: Any],
      defaults: AlarmkitPluginImpl.defaultStopButton
    )

    let id = UUID()

    let alertContent = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: label),
      stopButton: stopConfig.toAlarmButton()
    )
    let presentation = AlarmPresentation(alert: alertContent)
    let tintColor = parseTintColor(from: args)
    let metadata = parseMetadata(from: args)
    let attributes = AlarmAttributes<NeverMetadata>(
      presentation: presentation,
      metadata: metadata,
      tintColor: tintColor
    )

    // 6. Configure and schedule
    let soundPath = parseSoundPath(from: args)
    let config = AlarmManager.AlarmConfiguration<NeverMetadata>(
      schedule: .relative(schedule),
      attributes: attributes,
      sound: resolveSoundAsset(soundPath)
    )

    storeAlarmMeta(
      alarmId: id.uuidString,
      label: label,
      tintColorHex: hexString(from: tintColor),
      createdAt: Date().timeIntervalSince1970,
      metadata: metadata
    )
    storeButtonTints(alarmId: id.uuidString, stop: stopConfig)

    do {
      let alarm = try await manager.schedule(
        id: id, configuration: config
      )
      result(alarm.id.uuidString)
    } catch {
      removeAlarmPersistence(id.uuidString)
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
        let alarmsData = alarms.map { $0.toDictionary() }
        pruneOrphanedPersistence(liveIds: Set(alarms.map { $0.id.uuidString }))
        result(alarmsData)
    } catch {
        result(FlutterError(
            code: "GET_ALARMS_ERROR",
            message: "Failed to get alarms: \(error.localizedDescription)",
            details: nil
        ))
    }
  }

  /// Delete persisted App Group state for alarms that no longer exist. Guarded
  /// by a grace period on the stored `createdAt` so a concurrent in-flight
  /// schedule (persisted but not yet visible in `manager.alarms`) isn't pruned.
  private func pruneOrphanedPersistence(liveIds: Set<String>) {
    guard let defaults = UserDefaults(suiteName: AlarmkitPluginImpl.appGroupId) else { return }
    let graceSeconds: TimeInterval = 60
    let now = Date().timeIntervalSince1970
    let all = defaults.dictionaryRepresentation()

    // Collect candidate ids from both metadata and tint keys, so legacy
    // `alarm_tints_*` entries written before metadata existed are also pruned.
    var candidateIds = Set<String>()
    for key in all.keys {
      if key.hasPrefix("alarm_meta_") {
        candidateIds.insert(String(key.dropFirst("alarm_meta_".count)))
      } else if key.hasPrefix("alarm_tints_") {
        candidateIds.insert(String(key.dropFirst("alarm_tints_".count)))
      }
    }

    for alarmId in candidateIds {
      if liveIds.contains(alarmId) { continue }
      // Keep entries still inside the grace window (covers in-flight schedules).
      // Schedules always write metadata before tints, so a tints-only entry can
      // only be a legacy alarm with no createdAt — safe to prune once orphaned.
      if let meta = all["alarm_meta_\(alarmId)"] as? [String: Any],
         let createdAt = meta["createdAt"] as? TimeInterval,
         now - createdAt <= graceSeconds {
        continue
      }
      removeAlarmPersistence(alarmId)
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
      removeAlarmPersistence(parsed.alarmId)
      result(true)
    } catch {
      result(FlutterError(
        code: "CANCEL_ERROR",
        message: "Failed to cancel alarm \(parsed.alarmId): \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  private func cancelAll(result: @escaping FlutterResult) async {
    let manager = AlarmManager.shared

    let alarms: [Alarm]
    do {
      alarms = try manager.alarms
    } catch {
      result(FlutterError(
        code: "CANCEL_ALL_ERROR",
        message: "Failed to fetch alarms: \(error.localizedDescription)",
        details: nil
      ))
      return
    }

    // Attempt every alarm independently so one failure doesn't block the rest.
    var failedIds: [String] = []
    for alarm in alarms {
      do {
        try manager.cancel(id: alarm.id)
        removeAlarmPersistence(alarm.id.uuidString)
      } catch {
        failedIds.append(alarm.id.uuidString)
      }
    }

    if failedIds.isEmpty {
      result(nil)
    } else {
      result(FlutterError(
        code: "CANCEL_ALL_ERROR",
        message: "Failed to cancel \(failedIds.count) of \(alarms.count) alarm(s).",
        details: failedIds
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
