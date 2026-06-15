/// The days of the week, used to configure recurrent alarms.
///
/// Enum positions are bit-significant: see [toBitmask]. This ordering must
/// stay in lockstep with the native `decodeWeekdays` decoder in
/// `ios/flutter_alarmkit/Sources/flutter_alarmkit/FlutterAlarmkitPlugin.swift`,
/// which maps bit 0 to Monday.
enum Weekday {
  /// Monday (enum position 0).
  monday,

  /// Tuesday (enum position 1).
  tuesday,

  /// Wednesday (enum position 2).
  wednesday,

  /// Thursday (enum position 3).
  thursday,

  /// Friday (enum position 4).
  friday,

  /// Saturday (enum position 5).
  saturday,

  /// Sunday (enum position 6).
  sunday;

  /// Converts a set of weekdays to a bitmask.
  ///
  /// Each weekday occupies the bit at its enum position:
  /// - monday → bit 0 (`1 << 0`)
  /// - tuesday → bit 1 (`1 << 1`)
  /// - wednesday → bit 2 (`1 << 2`)
  /// - thursday → bit 3 (`1 << 3`)
  /// - friday → bit 4 (`1 << 4`)
  /// - saturday → bit 5 (`1 << 5`)
  /// - sunday → bit 6 (`1 << 6`)
  ///
  /// An empty set yields `0`. This ordering must match the Swift
  /// `decodeWeekdays` decoder.
  static int toBitmask(Set<Weekday> weekdays) {
    return weekdays.fold(0, (mask, day) => mask | (1 << day.index));
  }
}
