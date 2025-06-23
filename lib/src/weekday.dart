/// Represents the days of the week for recurrent alarms.
// ignore_for_file: public_member_api_docs, dangling_library_doc_comments

enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  /// Converts a set of weekdays to a bitmask.
  ///
  /// The bitmask is constructed as follows:
  /// - Monday (0) = 1 << 0
  /// - Tuesday (1) = 1 << 1
  /// - Wednesday (2) = 1 << 2
  /// - Thursday (3) = 1 << 3
  /// - Friday (4) = 1 << 4
  /// - Saturday (5) = 1 << 5
  /// - Sunday (6) = 1 << 6
  static int toBitmask(Set<Weekday> weekdays) {
    return weekdays.fold(0, (mask, day) => mask | (1 << day.index));
  }
}
