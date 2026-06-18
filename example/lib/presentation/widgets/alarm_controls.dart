import 'package:flutter/material.dart';
// Hide the plugin's AlarmState enum: this file uses the bloc's AlarmState
// (its state class) with BlocBuilder.
import 'package:flutter_alarmkit/flutter_alarmkit.dart' hide AlarmState;
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
                              soundPath: 'assets/marimba.caf',
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
                              soundPath: 'assets/marimba.caf',
                            ),
                          );
                    }
                  : null,
              child: const Text('Schedule Countdown Alarm (10s)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: state.authStatus == 'Granted'
                  ? () async {
                      final plugin = FlutterAlarmkit();
                      final id = await plugin.setCountdownAlarm(
                        countdownDurationInSeconds: 15,
                        repeatDurationInSeconds: 5,
                        label: 'Custom UI Test',
                        tintColor: '#FF6600',
                        uiConfig: const AlarmUIConfig(
                          stopButton: AlarmButtonConfig(
                            text: 'End',
                            icon: 'xmark.circle',
                            tintColor: '#8B0000', // dark red
                          ),
                          pauseButton: AlarmButtonConfig(
                            text: 'Hold',
                            icon: 'hand.raised',
                            tintColor: '#4B0082', // indigo
                          ),
                          resumeButton: AlarmButtonConfig(
                            text: 'Go',
                            icon: 'play.fill',
                            tintColor: '#006400', // dark green
                          ),
                          repeatButton: AlarmButtonConfig(
                            text: 'Again',
                            icon: 'arrow.clockwise',
                          ),
                          countdownTitle: 'Counting down...',
                          pausedTitle: 'On hold',
                        ),
                      );
                      debugPrint('Custom alarm ID: $id');
                    }
                  : null,
              child: const Text('Custom UI Alarm (15s)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: state.authStatus == 'Granted'
                  ? () async {
                      final plugin = FlutterAlarmkit();
                      final id = await plugin.scheduleOneShotAlarm(
                        timestamp: DateTime.now()
                            .add(const Duration(seconds: 5))
                            .millisecondsSinceEpoch
                            .toDouble(),
                        label: 'Open-App Alarm',
                        tintColor: '#5856D6',
                        uiConfig: const AlarmUIConfig(
                          openAppButton: AlarmButtonConfig(
                            text: 'Open',
                            icon: 'arrow.up.forward.app',
                            tintColor: '#5856D6',
                          ),
                        ),
                      );
                      debugPrint('Open-app alarm ID: $id');
                    }
                  : null,
              child: const Text('Open-App Alarm (5s)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: state.authStatus == 'Granted'
                  ? () async {
                      final plugin = FlutterAlarmkit();
                      final id = await plugin.scheduleOneShotAlarm(
                        timestamp: DateTime.now()
                            .add(const Duration(seconds: 5))
                            .millisecondsSinceEpoch
                            .toDouble(),
                        label: 'Medication',
                        tintColor: '#FF2D55',
                        metadata: const AlarmMetadata(
                          icon: 'pills.fill',
                          subtitle: 'Take 2 tablets',
                        ),
                      );
                      debugPrint('Metadata alarm ID: $id');
                    }
                  : null,
              child: const Text('Metadata Alarm (5s)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: state.authStatus == 'Granted'
                  ? () async {
                      final fireAt =
                          DateTime.now().add(const Duration(minutes: 1));
                      await FlutterAlarmkit().scheduleRecurrentAlarm(
                        weekdays: Weekday.everyday,
                        hour: fireAt.hour,
                        minute: fireAt.minute,
                        label: 'Daily Alarm',
                        tintColor: '#34C759',
                      );
                    }
                  : null,
              child: const Text('Daily Alarm (~1 min, repeats)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: state.authStatus == 'Granted'
                  ? () async {
                      final fireAt =
                          DateTime.now().add(const Duration(minutes: 1));
                      await FlutterAlarmkit().scheduleRecurrentAlarm(
                        weekdays: const {},
                        hour: fireAt.hour,
                        minute: fireAt.minute,
                        label: 'Once Alarm',
                        tintColor: '#FF9500',
                      );
                    }
                  : null,
              child: const Text('Once at Time (~1 min)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FlutterAlarmkit().cancelAll();
              },
              child: const Text('Cancel All'),
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
