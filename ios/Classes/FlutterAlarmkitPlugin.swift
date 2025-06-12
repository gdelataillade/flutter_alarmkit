import Flutter
import UIKit
import AlarmKit

public class FlutterAlarmkitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_alarmkit", binaryMessenger: registrar.messenger())
    let instance = FlutterAlarmkitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "requestAuthorization":
      if #available(iOS 26.0, *) {
        Task {
          await self.requestAuthorization(result: result)
        }
      } else {
        result(FlutterError(code: "UNSUPPORTED_VERSION",
                           message: "AlarmKit is only available on iOS 26.0 and above",
                           details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 26.0, *)
  private func requestAuthorization(result: @escaping FlutterResult) async {
    do {
      _ = try await AlarmManager.shared.requestAuthorization()
      result(true)
    } catch {
      result(FlutterError(code: "AUTH_ERROR",
                         message: "Failed to request alarm authorization: \(error)",
                         details: nil))
    }
  }
}
