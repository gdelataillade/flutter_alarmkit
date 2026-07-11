import 'package:flutter/cupertino.dart';
// Hide the plugin's AlarmState enum: this file uses the bloc's AlarmState
// (its state class) with BlocBuilder.
import 'package:flutter_alarmkit/flutter_alarmkit.dart' hide AlarmState;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/alarm_bloc.dart';
import '../example_theme.dart';

class AlarmControls extends StatefulWidget {
  const AlarmControls({super.key});

  @override
  State<AlarmControls> createState() => _AlarmControlsState();
}

class _AlarmControlsState extends State<AlarmControls> {
  bool _showMore = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlarmBloc, AlarmState>(
      builder: (context, state) {
        final granted = state.authStatus == 'Granted';
        final bloc = context.read<AlarmBloc>();
        final plugin = FlutterAlarmkit();

        final extraExamples = <_ExampleAction>[
          _ExampleAction(
            icon: CupertinoIcons.heart_fill,
            title: 'Medication alarm',
            subtitle: 'One-shot in 5 sec · metadata',
            color: CupertinoColors.systemPink,
            onPressed: () async {
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
            },
          ),
          _ExampleAction(
            icon: CupertinoIcons.timer_fill,
            title: 'Medication timer',
            subtitle: '60 sec countdown · metadata',
            color: CupertinoColors.systemPurple,
            onPressed: () async {
              final id = await plugin.setCountdownAlarm(
                countdownDurationInSeconds: 60,
                repeatDurationInSeconds: 10,
                label: 'Medication',
                tintColor: '#AF52DE',
                metadata: const AlarmMetadata(
                  icon: 'pills.fill',
                  subtitle: 'Take 2 tablets',
                ),
              );
              debugPrint('Countdown+metadata alarm ID: $id');
            },
          ),
          _ExampleAction(
            icon: CupertinoIcons.timer,
            title: 'Simple timer',
            subtitle: '15 sec countdown · no repeat',
            color: CupertinoColors.systemTeal,
            onPressed: () async {
              final id = await plugin.setCountdownAlarm(
                countdownDurationInSeconds: 15,
                repeatDurationInSeconds: 0,
                label: 'Simple Timer',
                tintColor: '#30B0C7',
              );
              debugPrint('Simple timer alarm ID: $id');
            },
          ),
          _ExampleAction(
            icon: CupertinoIcons.slider_horizontal_3,
            title: 'Custom alarm UI',
            subtitle: '15 sec countdown · custom buttons',
            color: CupertinoColors.systemOrange,
            onPressed: () async {
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
            },
          ),
          _ExampleAction(
            icon: CupertinoIcons.repeat,
            title: 'Daily alarm',
            subtitle: 'Starts in about 1 min · repeats',
            color: CupertinoColors.systemGreen,
            onPressed: () async {
              final at = DateTime.now().add(const Duration(minutes: 1));
              final id = await plugin.scheduleRecurrentAlarm(
                weekdays: Weekday.everyday,
                hour: at.hour,
                minute: at.minute,
                label: 'Daily Alarm',
                tintColor: '#34C759',
              );
              debugPrint('Daily alarm ID: $id');
            },
          ),
          _ExampleAction(
            icon: CupertinoIcons.calendar,
            title: 'Scheduled once',
            subtitle: 'At a clock time · about 1 min',
            color: CupertinoColors.systemBlue,
            onPressed: () async {
              final at = DateTime.now().add(const Duration(minutes: 1));
              final id = await plugin.scheduleRecurrentAlarm(
                weekdays: const {},
                hour: at.hour,
                minute: at.minute,
                label: 'Once Alarm',
                tintColor: '#007AFF',
              );
              debugPrint('Once alarm ID: $id');
            },
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(
              title: 'Quick start',
              subtitle: 'Run the two most common plugin calls.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    value: '5s',
                    label: 'One-shot alarm',
                    icon: CupertinoIcons.alarm_fill,
                    emphasized: true,
                    onPressed: granted
                        ? () => bloc.add(
                              ScheduleOneShotAlarm(
                                timestamp: DateTime.now()
                                    .add(const Duration(seconds: 5)),
                                label: 'Test Alarm',
                                tintColor: '#FF5A3C',
                                soundPath: 'assets/marimba.caf',
                              ),
                            )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    value: '10s',
                    label: 'Countdown',
                    icon: CupertinoIcons.timer_fill,
                    onPressed: granted
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: ExampleTheme.cardDecoration(context),
              child: Column(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    minimumSize: const Size(double.infinity, 52),
                    onPressed: () => setState(() => _showMore = !_showMore),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.square_grid_2x2, size: 19),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Text(
                            'More examples',
                            style: TextStyle(
                              color: CupertinoColors.label,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${extraExamples.length}',
                          style: const TextStyle(
                            color: ExampleTheme.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _showMore
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          color: ExampleTheme.secondaryText,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  if (_showMore) ...[
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(left: 56),
                      color: ExampleTheme.resolve(context, ExampleTheme.border),
                    ),
                    for (var index = 0;
                        index < extraExamples.length;
                        index++) ...[
                      _ExampleRow(
                        action: extraExamples[index],
                        enabled: granted,
                      ),
                      if (index != extraExamples.length - 1)
                        Container(
                          height: 1,
                          margin: const EdgeInsets.only(left: 56),
                          color: ExampleTheme.resolve(
                            context,
                            ExampleTheme.border,
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: ExampleTheme.secondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.value,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final foreground = emphasized
        ? CupertinoColors.white
        : CupertinoColors.label.resolveFrom(context);

    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          height: 132,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: emphasized
              ? BoxDecoration(
                  color: ExampleTheme.resolve(context, ExampleTheme.accent),
                  borderRadius: BorderRadius.circular(20),
                )
              : ExampleTheme.cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: foreground, size: 20),
                  Icon(
                    CupertinoIcons.arrow_up_right,
                    color: foreground.withAlpha(170),
                    size: 16,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: foreground,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground.withAlpha(210),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleAction {
  const _ExampleAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;
}

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({required this.action, required this.enabled});

  final _ExampleAction action;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = ExampleTheme.resolve(context, action.color);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        minimumSize: const Size(double.infinity, 64),
        onPressed: enabled ? action.onPressed : null,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: const TextStyle(
                      color: CupertinoColors.label,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle,
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
            const Icon(
              CupertinoIcons.play_circle_fill,
              color: ExampleTheme.secondaryText,
              size: 23,
            ),
          ],
        ),
      ),
    );
  }
}
