import 'package:flutter/cupertino.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Prefixed: the bloc's AlarmState (state class) would otherwise clash with the
// plugin's AlarmState enum used below.
import '../bloc/alarm_bloc.dart' as bloc;
import '../example_theme.dart';

/// Live list of the alarms known to the system, driven by getAlarms() and the
/// alarmUpdates() stream.
class AlarmsList extends StatelessWidget {
  const AlarmsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<bloc.AlarmBloc, bloc.AlarmState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Live state reported by AlarmKit.',
                        style: TextStyle(
                          color: ExampleTheme.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ExampleTheme.resolve(
                      context,
                      ExampleTheme.subtleSurface,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.alarms.length}',
                    style: const TextStyle(
                      color: ExampleTheme.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: ExampleTheme.cardDecoration(context),
              child: state.alarms.isEmpty
                  ? const _EmptyAlarms()
                  : Column(
                      children: [
                        for (var index = 0;
                            index < state.alarms.length;
                            index++) ...[
                          _AlarmRow(alarm: state.alarms[index]),
                          if (index != state.alarms.length - 1)
                            Container(
                              height: 1,
                              margin: const EdgeInsets.only(left: 60),
                              color: ExampleTheme.resolve(
                                context,
                                ExampleTheme.border,
                              ),
                            ),
                        ],
                        Container(
                          height: 1,
                          color: ExampleTheme.resolve(
                            context,
                            ExampleTheme.border,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              if (state.lastAlarmId != null)
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 40),
                                  onPressed: () =>
                                      context.read<bloc.AlarmBloc>().add(
                                            bloc.StopAlarm(
                                              alarmId: state.lastAlarmId!,
                                            ),
                                          ),
                                  child: const Text('Stop last'),
                                ),
                              const Spacer(),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 40),
                                onPressed: () async {
                                  await FlutterAlarmkit().cancelAll();
                                  debugPrint('Cancelled all alarms');
                                },
                                child: const Text(
                                  'Cancel all',
                                  style: TextStyle(
                                    color: CupertinoColors.systemRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyAlarms extends StatelessWidget {
  const _EmptyAlarms();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ExampleTheme.resolve(
                context,
                ExampleTheme.subtleSurface,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.alarm,
              color: ExampleTheme.secondaryText,
              size: 21,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No alarms scheduled',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Run a quick example to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ExampleTheme.secondaryText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmRow extends StatelessWidget {
  const _AlarmRow({required this.alarm});

  final Alarm alarm;

  @override
  Widget build(BuildContext context) {
    final tint = _tintColor(alarm.tintColor) ??
        CupertinoColors.systemBlue.resolveFrom(context);
    final stateColor = _stateColor(context, alarm.state);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withAlpha(28),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(CupertinoIcons.alarm_fill, color: tint, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alarm.label ?? 'Untitled alarm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: stateColor.withAlpha(24),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        alarm.state.name,
                        style: TextStyle(
                          color: stateColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _subtitle(alarm),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ExampleTheme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(42, 42),
            onPressed: () => context
                .read<bloc.AlarmBloc>()
                .add(bloc.CancelAlarm(alarmId: alarm.id)),
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              color: ExampleTheme.secondaryText,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

String _subtitle(Alarm alarm) {
  final parts = <String>[_scheduleSummary(alarm)];
  final sub = alarm.metadata?.subtitle;
  if (sub != null && sub.isNotEmpty) parts.add(sub);
  return parts.join(' · ');
}

Color _stateColor(BuildContext context, AlarmState state) {
  final color = switch (state) {
    AlarmState.alerting => CupertinoColors.systemRed,
    AlarmState.countdown => CupertinoColors.systemBlue,
    AlarmState.paused => CupertinoColors.systemOrange,
    AlarmState.scheduled => CupertinoColors.systemGreen,
    AlarmState.unknown => CupertinoColors.systemGrey,
  };
  return color.resolveFrom(context);
}

String _scheduleSummary(Alarm alarm) {
  final schedule = alarm.schedule;
  if (schedule is FixedAlarmSchedule) {
    return 'Once · ${_formatDateTime(schedule.date)}';
  }
  if (schedule is RelativeAlarmSchedule) {
    final time = '${_two(schedule.hour)}:${_two(schedule.minute)}';
    if (schedule.weekdays.isEmpty) return 'Once · $time';
    return '$time · ${_weekdayLabels(schedule.weekdays)}';
  }
  if (schedule is UnknownAlarmSchedule) {
    return 'Unknown schedule';
  }
  final countdown = alarm.countdownDuration;
  if (countdown != null) {
    final pre = countdown.preAlert;
    return pre != null ? 'Countdown · ${pre.round()}s' : 'Countdown';
  }
  return '—';
}

String _weekdayLabels(Set<Weekday> days) {
  const names = {
    Weekday.monday: 'Mon',
    Weekday.tuesday: 'Tue',
    Weekday.wednesday: 'Wed',
    Weekday.thursday: 'Thu',
    Weekday.friday: 'Fri',
    Weekday.saturday: 'Sat',
    Weekday.sunday: 'Sun',
  };
  return Weekday.values
      .where(days.contains)
      .map((day) => names[day])
      .join(', ');
}

String _formatDateTime(DateTime date) =>
    '${date.year}-${_two(date.month)}-${_two(date.day)} '
    '${_two(date.hour)}:${_two(date.minute)}';

String _two(int n) => n.toString().padLeft(2, '0');

Color? _tintColor(String? hex) {
  if (hex == null) return null;
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length != 6) return null;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(0xFF000000 | parsed);
}
