import AlarmKit

// The name is retained (rather than renamed) to preserve the registered
// `AlarmAttributes<NeverMetadata>` Live Activity type identity across plugin
// upgrades. Both fields are optional, so an alarm scheduled without metadata
// still encodes to `{}` and older `{}` payloads decode cleanly to all-nil.
//
// Field set must stay in sync with the copies in the widget templates
// (ios/WidgetTemplates/ and example/ios/AlarmkitWidget/).
@available(iOS 26.0, *)
struct NeverMetadata: AlarmMetadata, Codable, Hashable {
  var icon: String?
  var subtitle: String?
}
