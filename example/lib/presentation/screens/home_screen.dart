import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarm_bloc.dart';
import '../widgets/platform_info.dart';
import '../widgets/auth_section.dart';
import '../widgets/alarm_controls.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the BLoC when the screen is created
    context.read<AlarmBloc>().add(InitializeAlarm());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AlarmKit Example 0.0.4')),
      body: BlocBuilder<AlarmBloc, AlarmState>(
        builder: (context, state) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PlatformInfo(platformVersion: state.platformVersion),
                  const SizedBox(height: 20),
                  const AuthSection(),
                  const SizedBox(height: 40),
                  const AlarmControls(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
