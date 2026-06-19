import 'package:flutter/cupertino.dart';
// Hide the plugin's AlarmState enum: this file uses the bloc's AlarmState
// (its state class) with BlocBuilder.
import 'package:flutter_alarmkit/flutter_alarmkit.dart' hide AlarmState;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarm_bloc.dart';

class AlarmControls extends StatelessWidget {
  const AlarmControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlarmBloc, AlarmState>(
      builder: (context, state) {
        final granted = state.authStatus == 'Granted';
        final bloc = context.read<AlarmBloc>();
        final plugin = FlutterAlarmkit();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('LAST ACTION'),
              children: [
                CupertinoListTile(
                  title: Text(state.scheduleStatus),
                  subtitle: state.lastAlarmId != null
                      ? Text('ID: ${state.lastAlarmId}')
                      : null,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  _button(
                    'One-Shot (5s)',
                    granted
                        ? () => bloc.add(
                              ScheduleOneShotAlarm(
                                timestamp:
                                    DateTime.now().add(const Duration(seconds: 5)),
                                label: 'Test Alarm',
                                tintColor: '#34C759',
                                soundPath: 'assets/marimba.caf',
                              ),
                            )
                        : null,
                  ),
                  _button(
                    'Countdown (10s)',
                    granted
                        ? () => bloc.add(
                              const ScheduleCountdownAlarm(
                                countdownDurationInSeconds: 10,
                                repeatDurationInSeconds: 5,
                                label: 'Test Countdown',
                                tintColor: '#007AFF',
                                soundPath: 'assets/marimba.caf',
                              ),
                            )
                        : null,
                  ),
                  _button(
                    'Countdown + Metadata (60s)',
                    granted
                        ? () async {
                            final id = await plugin.setCountdownAlarm(
                              countdownDurationInSeconds: 60,
                              repeatDurationInSeconds: 10,
                              label: 'Medication',
                              tintColor: '#FF2D55',
                              metadata: const AlarmMetadata(
                                icon: 'pills.fill',
                                subtitle: 'Take 2 tablets',
                              ),
                            );
                            debugPrint('Countdown+metadata alarm ID: $id');
                          }
                        : null,
                  ),
                  _button(
                    'One-Shot + Metadata (5s)',
                    granted
                        ? () async {
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
                  ),
                  _button(
                    'Custom UI Countdown (15s)',
                    granted
                        ? () async {
                            final id = await plugin.setCountdownAlarm(
                              countdownDurationInSeconds: 15,
                              repeatDurationInSeconds: 5,
                              label: 'Custom UI Test',
                              tintColor: '#FF6600',
                              uiConfig: const AlarmUIConfig(
                                stopButton: AlarmButtonConfig(
                                  text: 'End',
                                  icon: 'xmark.circle',
                                  tintColor: '#8B0000',
                                ),
                                pauseButton: AlarmButtonConfig(
                                  text: 'Hold',
                                  icon: 'hand.raised',
                                  tintColor: '#4B0082',
                                ),
                                resumeButton: AlarmButtonConfig(
                                  text: 'Go',
                                  icon: 'play.fill',
                                  tintColor: '#006400',
                                ),
                                repeatButton: AlarmButtonConfig(
                                  text: 'Again',
                                  icon: 'arrow.clockwise',
                                ),
                                countdownTitle: 'Counting down...',
                                pausedTitle: 'On hold',
                              ),
                            );
                            debugPrint('Custom UI alarm ID: $id');
                          }
                        : null,
                  ),
                  _button(
                    'Daily (~1 min, repeats)',
                    granted
                        ? () async {
                            final at = DateTime.now().add(const Duration(minutes: 1));
                            final id = await plugin.scheduleRecurrentAlarm(
                              weekdays: Weekday.everyday,
                              hour: at.hour,
                              minute: at.minute,
                              label: 'Daily Alarm',
                              tintColor: '#34C759',
                            );
                            debugPrint('Daily alarm ID: $id');
                          }
                        : null,
                  ),
                  _button(
                    'Once at Time (~1 min)',
                    granted
                        ? () async {
                            final at = DateTime.now().add(const Duration(minutes: 1));
                            final id = await plugin.scheduleRecurrentAlarm(
                              weekdays: const {},
                              hour: at.hour,
                              minute: at.minute,
                              label: 'Once Alarm',
                              tintColor: '#FF9500',
                            );
                            debugPrint('Once alarm ID: $id');
                          }
                        : null,
                  ),
                  _button(
                    'Stop Last Alarm',
                    state.lastAlarmId != null
                        ? () => bloc.add(StopAlarm(alarmId: state.lastAlarmId!))
                        : null,
                    destructive: true,
                  ),
                  _button(
                    'Cancel All',
                    () async {
                      await plugin.cancelAll();
                      debugPrint('Cancelled all alarms');
                    },
                    destructive: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _button(String label, VoidCallback? onPressed, {bool destructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          color: destructive
              ? CupertinoColors.destructiveRed
              : CupertinoColors.activeBlue,
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}
