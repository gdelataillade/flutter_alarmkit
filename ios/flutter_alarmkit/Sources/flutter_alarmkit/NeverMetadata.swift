import AlarmKit

// The name is retained (rather than renamed) to preserve the registered
// `AlarmAttributes<NeverMetadata>` Live Activity type identity across plugin
// upgrades. Every field is optional, so an alarm scheduled without metadata
// still encodes to `{}` and older payloads decode cleanly with the missing
// fields as nil.
//
// `icon`/`subtitle` are displayable metadata; the `*Tint` fields carry the
// button tint colors (`#RRGGBB`) to the widget, since AlarmKit's `AlarmButton`
// has no tint.
//
// Field set must stay in sync with the copies in the widget templates
// (ios/WidgetTemplates/ and example/ios/AlarmkitWidget/).
@available(iOS 26.0, *)
@available(macCatalyst, unavailable)
struct NeverMetadata: AlarmMetadata, Codable, Hashable {
  var icon: String?
  var subtitle: String?
  var stopTint: String?
  var pauseTint: String?
  var resumeTint: String?
  var repeatTint: String?
}
