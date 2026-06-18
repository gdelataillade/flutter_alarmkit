/// The app's authorization to schedule alarms, mirroring AlarmKit's
/// `AlarmManager.AuthorizationState`.
enum AlarmAuthorizationState {
  /// The user has not yet been asked for permission.
  notDetermined,

  /// Permission has been denied (or not granted).
  denied,

  /// The app is allowed to schedule alarms.
  authorized,

  /// The state could not be mapped — e.g. a future AlarmKit state this
  /// version of the plugin does not yet know about.
  unknown;

  /// Maps the raw integer from the platform channel to an
  /// [AlarmAuthorizationState].
  ///
  /// `0` → [notDetermined], `2` → [denied], `3` → [authorized]. `null`, the
  /// `-1` sentinel, and any unrecognized value map to [unknown], keeping the
  /// API forward-compatible with future iOS releases.
  static AlarmAuthorizationState fromRaw(int? raw) {
    switch (raw) {
      case 0:
        return AlarmAuthorizationState.notDetermined;
      case 2:
        return AlarmAuthorizationState.denied;
      case 3:
        return AlarmAuthorizationState.authorized;
      default:
        return AlarmAuthorizationState.unknown;
    }
  }
}
