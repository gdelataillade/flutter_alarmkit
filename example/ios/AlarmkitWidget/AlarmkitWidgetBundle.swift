import WidgetKit
import SwiftUI

@available(iOS 26.0, *)
@available(macCatalyst, unavailable)
@main
struct AlarmLiveActivityBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    AlarmkitLiveActivity()
  }
}
