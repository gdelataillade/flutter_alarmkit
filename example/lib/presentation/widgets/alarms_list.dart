import 'package:flutter/cupertino.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Prefixed: the bloc's AlarmState (state class) would otherwise clash with the
// plugin's AlarmState enum used below.
import '../bloc/alarm_bloc.dart' as bloc;

/// Live list of the alarms known to the system, driven by getAlarms() and the
/// alarmUpdates() stream.
class AlarmsList extends StatelessWidget {
  const AlarmsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<bloc.AlarmBloc, bloc.AlarmState>(
      builder: (context, state) {
        return CupertinoListSection.insetGrouped(
          header: const Text('SCHEDULED ALARMS'),
          children: [
            if (state.alarms.isEmpty)
              const CupertinoListTile(
                title: Text(
                  'No scheduled alarms',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              )
            else
              for (final alarm in state.alarms)
                CupertinoListTile(
                  leading: Icon(
                    CupertinoIcons.alarm,
                    color: _tintColor(alarm.tintColor) ??
                        CupertinoColors.activeBlue,
                  ),
                  title: Text(alarm.label ?? '(no label)'),
                  subtitle: Text(_subtitle(alarm)),
                  additionalInfo: Text(
                    alarm.state.name,
                    style: TextStyle(color: _stateColor(alarm.state)),
                  ),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => context
                        .read<bloc.AlarmBloc>()
                        .add(bloc.CancelAlarm(alarmId: alarm.id)),
                    child: const Icon(CupertinoIcons.delete, size: 20),
                  ),
                ),
          ],
        );
      },
    );
  }
}

String _subtitle(Alarm alarm) {
  final parts = <String>[_scheduleSummary(alarm)];
  final sub = alarm.metadata?.subtitle;
  if (sub != null && sub.isNotEmpty) parts.add(sub);
  return parts.join(' · ');
}

Color _stateColor(AlarmState state) {
  switch (state) {
    case AlarmState.alerting:
      return CupertinoColors.systemRed;
    case AlarmState.countdown:
      return CupertinoColors.activeBlue;
    case AlarmState.paused:
      return CupertinoColors.systemOrange;
    case AlarmState.scheduled:
      return CupertinoColors.systemGreen;
    case AlarmState.unknown:
      return CupertinoColors.systemGrey;
  }
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
