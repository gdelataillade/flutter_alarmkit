import Flutter
import UIKit
import AlarmKit

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
      result(FlutterError(code: "AUTH_ERROR",
                         message: "Failed to request alarm authorization: \(error)",
                         details: nil))
    }
  }

  private func scheduleOneShotAlarm(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) async {
    let manager = AlarmManager.shared
    
    // Handle authorization state
    switch manager.authorizationState {
    case .notDetermined:
      // Request authorization if not determined
      do {
        let authorizationState = try await manager.requestAuthorization()
        if authorizationState != .authorized {
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
    case .authorized:
      // Already authorized, proceed
      break
    case .denied:
      result(FlutterError(
        code: "NOT_AUTHORIZED",
        message: "AlarmKit authorization denied or restricted. Please enable in Settings.",
        details: nil
      ))
      return
    @unknown default:
      result(FlutterError(
        code: "UNKNOWN_AUTH_STATE",
        message: "Unknown authorization state: \(manager.authorizationState)",
        details: nil
      ))
      return
    }

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

    let alert = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: label),
      stopButton: .stopButton
    )
    let presentation = AlarmPresentation(alert: alert)

    // — use NeverMetadata here —
    let attributes = AlarmAttributes<NeverMetadata>(
      presentation: presentation,
      tintColor: .blue
    )

    let config = AlarmManager
      .AlarmConfiguration<NeverMetadata>(
        schedule: .fixed(date),
        attributes: attributes
      )

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
            var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
            components.hour = relative.time.hour
            components.minute = relative.time.minute
            return Calendar.current.date(from: components)
        @unknown default:
            return nil
        }
    }
}
