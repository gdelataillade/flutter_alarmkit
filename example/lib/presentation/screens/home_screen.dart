import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarm_bloc.dart';
import '../example_theme.dart';
import '../widgets/alarm_controls.dart';
import '../widgets/alarms_list.dart';
import '../widgets/log_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AlarmBloc>().add(InitializeAlarm());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: ExampleTheme.resolve(context, ExampleTheme.canvas),
      child: SafeArea(
        // The alarm UI stays hidden until permission is granted; only the
        // header and status/Allow card show beforehand.
        child: BlocBuilder<AlarmBloc, AlarmState>(
          buildWhen: (prev, curr) => prev.authStatus != curr.authStatus,
          builder: (context, state) {
            final granted = state.authStatus == 'Granted';
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                const _AppHeader(),
                const SizedBox(height: 20),
                const _StatusSection(),
                if (granted) ...const [
                  SizedBox(height: 28),
                  AlarmControls(),
                  SizedBox(height: 28),
                  AlarmsList(),
                  SizedBox(height: 20),
                  LogPanel(),
                ] else
                  const _PermissionHint(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ExampleTheme.resolve(context, ExampleTheme.accent),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            CupertinoIcons.alarm_fill,
            color: CupertinoColors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flutter AlarmKit',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Plugin example for iOS 26+',
                style: TextStyle(
                  color: ExampleTheme.secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionHint extends StatelessWidget {
  const _PermissionHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.bell_slash,
            color: ExampleTheme.secondaryText,
            size: 40,
          ),
          SizedBox(height: 14),
          Text(
            'Grant alarm permission to schedule\nand manage alarms.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ExampleTheme.secondaryText,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlarmBloc, AlarmState>(
      builder: (context, state) {
        final granted = state.authStatus == 'Granted';
        final requesting = state.authStatus == 'Requesting...';
        final statusColor = granted
            ? CupertinoColors.systemGreen.resolveFrom(context)
            : ExampleTheme.resolve(context, ExampleTheme.accent);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: ExampleTheme.cardDecoration(context),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(31),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  granted
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.lock_fill,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      granted ? 'Permission granted' : state.authStatus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      state.platformVersion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ExampleTheme.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!granted)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  color: ExampleTheme.resolve(context, ExampleTheme.accent),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: requesting
                      ? null
                      : () =>
                          context.read<AlarmBloc>().add(RequestAuthorization()),
                  child: Text(
                    requesting ? 'Waiting' : 'Allow',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
