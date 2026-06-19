import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'di/dependency_injection.dart';
import 'presentation/log_controller.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  // Mirror every debugPrint (plugin + app) into the in-app log panel.
  final flutterPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) logController.log(message);
    flutterPrint(message, wrapWidth: wrapWidth);
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'AlarmKit Example',
      home: BlocProvider(
        create: (_) => DependencyInjection.provideAlarmBloc(),
        child: const HomeScreen(),
      ),
    );
  }
}
