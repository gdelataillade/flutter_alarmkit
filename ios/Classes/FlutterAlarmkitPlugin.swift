import Flutter
import UIKit
import AlarmKit
import SwiftUI

@available(iOS 26.0, *)
public class FlutterAlarmkitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_alarmkit",
      binaryMessenger: registrar.messenger()
    )
    let instance = FlutterAlarmkitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "requestAuthorization":
      Task { await self.requestAuthorization(result: result) }

    case "scheduleOneShotAlarm":
      Task { await self.scheduleOneShotAlarm(call: call, result: result) }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  struct NeverMetadata: AlarmMetadata {}

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
      let authorizationState = try await AlarmManager.shared.requestAuthorization()
      switch authorizationState {
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

  // MARK: - Scheduling

  private func scheduleOneShotAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared

    // 1. Handle authorization state
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
          return
        }
      } catch {
        result(FlutterError(
          code: "AUTH_ERROR",
          message: "Failed to request alarm authorization: \(error)",
          details: nil
        ))
        return
      }

    case .denied:
      result(FlutterError(
        code: "NOT_AUTHORIZED",
        message: "AlarmKit authorization denied or restricted. Please enable in Settings.",
        details: nil
      ))
      return

    case .authorized:
      break
    @unknown default:
      result(FlutterError(
        code: "UNKNOWN_AUTH_STATE",
        message: "Unknown authorization state: \(manager.authorizationState)",
        details: nil
      ))
      return
    }

    // 2. Parse arguments
    guard
      let args = call.arguments as? [String: Any],
      let timestampMs = args["timestamp"] as? Double
    else {
      result(FlutterError(
        code: "BAD_ARGS",
        message: "Invalid arguments for scheduleOneShotAlarm",
        details: nil
      ))
      return
    }

    let label = args["label"] as? String ?? "Alarm"
    let date = Date(timeIntervalSince1970: timestampMs / 1000)

    // 3. Build the presentation
    let alert = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: label),
      stopButton: .stopButton
    )
    let presentation = AlarmPresentation(alert: alert)

    // 4. Determine tintColor (hex string like "#RRGGBB")
    let defaultTint = UIColor.blue
    let tint: UIColor
    if let hex = args["tintColor"] as? String,
       let parsed = color(from: hex) {
      tint = parsed
    } else {
      tint = defaultTint
    }

    // 5. Wrap in attributes
    let attributes = AlarmAttributes<NeverMetadata>(
      presentation: presentation,
      tintColor: Color(uiColor: tint)
    )

    // 6. Create one-shot fixed schedule
    let config = AlarmManager
      .AlarmConfiguration<NeverMetadata>(
        schedule: .fixed(date),
        attributes: attributes
      )

    // 7. Schedule and return the UUID string
    do {
      let alarm = try await manager.schedule(
        id: UUID(),
        configuration: config
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
}

// MARK: - Custom AlarmButton Styles

@available(iOS 26.0, *)
extension AlarmButton {
  static var openAppButton: Self {
    AlarmButton(text: "Open", textColor: .black, systemImageName: "swift")
  }
  static var pauseButton: Self {
    AlarmButton(text: "Pause", textColor: .black, systemImageName: "pause.fill")
  }
  static var resumeButton: Self {
    AlarmButton(text: "Start", textColor: .black, systemImageName: "play.fill")
  }
  static var repeatButton: Self {
    AlarmButton(text: "Repeat", textColor: .black, systemImageName: "repeat.circle")
  }
  static var stopButton: Self {
    AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle")
  }
}

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