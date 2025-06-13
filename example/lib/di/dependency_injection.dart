import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import '../data/repositories/alarm_repository_impl.dart';
import '../domain/repositories/alarm_repository.dart';
import '../presentation/bloc/alarm_bloc.dart';

class DependencyInjection {
  static AlarmRepository provideAlarmRepository() {
    return AlarmRepositoryImpl(FlutterAlarmkit());
  }

  static AlarmBloc provideAlarmBloc() {
    return AlarmBloc(provideAlarmRepository());
  }
}
