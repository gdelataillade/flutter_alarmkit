import 'package:flutter/material.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Prefixed: the bloc's AlarmState (state class) would otherwise clash with the
// plugin's AlarmState enum used below.
import '../bloc/alarm_bloc.dart' as bloc;

/// Live list of the alarms currently known to the system, driven by
/// `getAlarms()` and the `alarmUpdates()` stream.
class AlarmsList extends StatelessWidget {
  const AlarmsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<bloc.AlarmBloc, bloc.AlarmState>(
      builder: (context, state) {
        if (state.alarms.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No scheduled alarms',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Scheduled alarms:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.alarms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _AlarmTile(alarm: state.alarms[index]),
            ),
          ],
        );
      },
    );
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({required this.alarm});

  final Alarm alarm;

  @override
  Widget build(BuildContext context) {
    final tint = _tintColor(alarm.tintColor);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: tint == null
            ? const Icon(Icons.alarm)
            : CircleAvatar(backgroundColor: tint, radius: 12),
        title: Text(alarm.label ?? '(no label)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  alarm.state.name,
                  style: TextStyle(
                    color: _stateColor(alarm.state),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _scheduleSummary(alarm),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            Text(
              'ID: ${_shortId(alarm.id)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Cancel',
          onPressed: () => context
              .read<bloc.AlarmBloc>()
              .add(bloc.CancelAlarm(alarmId: alarm.id)),
        ),
      ),
    );
  }
}

Color _stateColor(AlarmState state) {
  switch (state) {
    case AlarmState.alerting:
      return Colors.red;
    case AlarmState.countdown:
      return Colors.blue;
    case AlarmState.paused:
      return Colors.orange;
    case AlarmState.scheduled:
      return Colors.green;
    case AlarmState.unknown:
      return Colors.grey;
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
  // Order by enum index for a stable display.
  return Weekday.values
      .where(days.contains)
      .map((day) => names[day])
      .join(', ');
}

String _formatDateTime(DateTime date) =>
    '${date.year}-${_two(date.month)}-${_two(date.day)} '
    '${_two(date.hour)}:${_two(date.minute)}';

String _two(int n) => n.toString().padLeft(2, '0');

String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);

Color? _tintColor(String? hex) {
  if (hex == null) return null;
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length != 6) return null;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(0xFF000000 | parsed);
}
