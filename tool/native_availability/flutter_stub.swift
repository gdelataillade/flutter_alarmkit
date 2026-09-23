import Foundation

// Minimal API surface needed to type-check the plugin's production Swift
// sources. This is not a behavioral Flutter mock.
public typealias FlutterResult = (Any?) -> Void
public typealias FlutterEventSink = (Any?) -> Void

public let FlutterMethodNotImplemented = NSObject()

public protocol FlutterBinaryMessenger: AnyObject {}

public protocol FlutterPluginRegistrar: AnyObject {
  func messenger() -> FlutterBinaryMessenger
  func addMethodCallDelegate(
    _ delegate: FlutterPlugin,
    channel: FlutterMethodChannel
  )
  func lookupKey(forAsset asset: String) -> String
}

public protocol FlutterPlugin: AnyObject {
  static func register(with registrar: FlutterPluginRegistrar)
}

public final class FlutterMethodCall {
  public let method: String
  public let arguments: Any?

  public init(methodName: String, arguments: Any?) {
    method = methodName
    self.arguments = arguments
  }
}

public final class FlutterMethodChannel {
  public init(name: String, binaryMessenger: FlutterBinaryMessenger) {}

  public func setMethodCallHandler(
    _ handler: ((FlutterMethodCall, @escaping FlutterResult) -> Void)?
  ) {}
}

public protocol FlutterStreamHandler: AnyObject {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError?

  func onCancel(withArguments arguments: Any?) -> FlutterError?
}

public final class FlutterEventChannel {
  public init(name: String, binaryMessenger: FlutterBinaryMessenger) {}

  public func setStreamHandler(_ handler: FlutterStreamHandler?) {}
}

public final class FlutterError: NSObject {
  public init(code: String, message: String?, details: Any?) {}
}
