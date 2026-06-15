import Flutter
import UIKit
import XCTest


@testable import flutter_alarmkit

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testGetPlatformVersion() throws {
    // The real implementation requires iOS 26; on older hosts the public
    // FlutterAlarmkitPlugin shell only exposes static registration, so there is
    // nothing to exercise here.
    guard #available(iOS 26.0, *) else {
      throw XCTSkip("AlarmKit requires iOS 26.0 or later")
    }
    let plugin = AlarmkitPluginImpl()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String, "iOS " + UIDevice.current.systemVersion)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
