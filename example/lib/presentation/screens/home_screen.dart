import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarm_bloc.dart';
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
      navigationBar: const CupertinoNavigationBar(middle: Text('AlarmKit')),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 8),
          children: const [
            _StatusSection(),
            AlarmControls(),
            AlarmsList(),
            LogPanel(),
          ],
        ),
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
        return CupertinoListSection.insetGrouped(
          header: const Text('STATUS'),
          children: [
            CupertinoListTile(
              title: const Text('Platform'),
              additionalInfo: Text(state.platformVersion),
            ),
            CupertinoListTile(
              title: const Text('Authorization'),
              additionalInfo: Text(
                state.authStatus,
                style: TextStyle(
                  color: granted
                      ? CupertinoColors.systemGreen.resolveFrom(context)
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              trailing: granted
                  ? null
                  : CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () =>
                          context.read<AlarmBloc>().add(RequestAuthorization()),
                      child: const Text('Request'),
                    ),
            ),
          ],
        );
      },
    );
  }
}
