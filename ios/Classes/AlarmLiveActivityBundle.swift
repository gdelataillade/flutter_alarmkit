import WidgetKit
import SwiftUI

@main
struct AlarmLiveActivityBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    AlarmKitWidgetLiveActivity()
  }
}