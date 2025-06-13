import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarm_bloc.dart';
import 'status_container.dart';

class AlarmControls extends StatelessWidget {
  const AlarmControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlarmBloc, AlarmState>(
      builder: (context, state) {
        return Column(
          children: [
            const Text(
              'Test Alarm:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StatusContainer(
              text: state.scheduleStatus,
              color: _getScheduleStatusColor(state.scheduleStatus),
              subtitle:
                  state.lastAlarmId != null ? 'ID: ${state.lastAlarmId}' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: state.authStatus == 'Granted'
                  ? () {
                      context.read<AlarmBloc>().add(
                            ScheduleOneShotAlarm(
                              timestamp: DateTime.now().add(
                                const Duration(seconds: 5),
                              ),
                              label: 'Test Alarm',
                              tintColor: '#00FF00',
                            ),
                          );
                    }
                  : null,
              child: const Text('Schedule Test Alarm (5s)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: state.authStatus == 'Granted'
                  ? () {
                      context.read<AlarmBloc>().add(
                            const ScheduleCountdownAlarm(
                              countdownDurationInSeconds: 10,
                              repeatDurationInSeconds: 5,
                              label: 'Test Countdown Alarm',
                              tintColor: '#0000FF',
                            ),
                          );
                    }
                  : null,
              child: const Text('Schedule Countdown Alarm (10s)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: state.lastAlarmId != null
                  ? () {
                      context.read<AlarmBloc>().add(
                            StopAlarm(alarmId: state.lastAlarmId!),
                          );
                    }
                  : null,
              child: const Text('Stop Alarm'),
            ),
          ],
        );
      },
    );
  }

  Color _getScheduleStatusColor(String status) {
    if (status == 'Alarm scheduled!') {
      return Colors.green;
    } else if (status == 'Scheduling...') {
      return Colors.orange;
    } else if (status.startsWith('Error') ||
        status == 'iOS 26.0+ required' ||
        status == 'Please grant alarm permission first') {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
