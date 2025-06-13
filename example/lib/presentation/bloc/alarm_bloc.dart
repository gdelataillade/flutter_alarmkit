import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/alarm_repository.dart';

// Events
abstract class AlarmEvent extends Equatable {
  const AlarmEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAlarm extends AlarmEvent {}

class RequestAuthorization extends AlarmEvent {}

class ScheduleOneShotAlarm extends AlarmEvent {
  final DateTime timestamp;
  final String label;
  final String tintColor;

  const ScheduleOneShotAlarm({
    required this.timestamp,
    required this.label,
    required this.tintColor,
  });

  @override
  List<Object?> get props => [timestamp, label, tintColor];
}

class ScheduleCountdownAlarm extends AlarmEvent {
  final int countdownDurationInSeconds;
  final int repeatDurationInSeconds;
  final String label;
  final String tintColor;

  const ScheduleCountdownAlarm({
    required this.countdownDurationInSeconds,
    required this.repeatDurationInSeconds,
    required this.label,
    required this.tintColor,
  });

  @override
  List<Object?> get props => [
        countdownDurationInSeconds,
        repeatDurationInSeconds,
        label,
        tintColor,
      ];
}

class CancelAlarm extends AlarmEvent {
  final String alarmId;

  const CancelAlarm({required this.alarmId});
}

class StopAlarm extends AlarmEvent {
  final String alarmId;

  const StopAlarm({required this.alarmId});
}

// State
class AlarmState extends Equatable {
  final String platformVersion;
  final String authStatus;
  final String scheduleStatus;
  final String? lastAlarmId;

  const AlarmState({
    this.platformVersion = 'Unknown',
    this.authStatus = 'Not requested',
    this.scheduleStatus = 'No alarm scheduled',
    this.lastAlarmId,
  });

  AlarmState copyWith({
    String? platformVersion,
    String? authStatus,
    String? scheduleStatus,
    String? lastAlarmId,
  }) {
    return AlarmState(
      platformVersion: platformVersion ?? this.platformVersion,
      authStatus: authStatus ?? this.authStatus,
      scheduleStatus: scheduleStatus ?? this.scheduleStatus,
      lastAlarmId: lastAlarmId ?? this.lastAlarmId,
    );
  }

  @override
  List<Object?> get props => [
        platformVersion,
        authStatus,
        scheduleStatus,
        lastAlarmId,
      ];
}

// BLoC
class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  final AlarmRepository _repository;

  AlarmBloc(this._repository) : super(const AlarmState()) {
    on<InitializeAlarm>(_onInitialize);
    on<RequestAuthorization>(_onRequestAuthorization);
    on<ScheduleOneShotAlarm>(_onScheduleOneShotAlarm);
    on<ScheduleCountdownAlarm>(_onScheduleCountdownAlarm);
    on<CancelAlarm>(_onCancelAlarm);
    on<StopAlarm>(_onStopAlarm);
  }

  Future<void> _onInitialize(
    InitializeAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    try {
      final version =
          await _repository.getPlatformVersion() ?? 'Unknown platform version';
      emit(state.copyWith(platformVersion: version));
    } catch (e) {
      emit(state.copyWith(platformVersion: 'Failed to get platform version.'));
    }
  }

  Future<void> _onRequestAuthorization(
    RequestAuthorization event,
    Emitter<AlarmState> emit,
  ) async {
    emit(state.copyWith(authStatus: 'Requesting...'));

    try {
      final granted = await _repository.requestAuthorization();
      emit(state.copyWith(
        authStatus: granted ? 'Granted' : 'Denied',
      ));
    } catch (e) {
      if (e.toString().contains('UNSUPPORTED_VERSION')) {
        emit(state.copyWith(authStatus: 'iOS 26.0+ required'));
      } else {
        emit(state.copyWith(authStatus: 'Error: $e'));
      }
    }
  }

  Future<void> _onScheduleOneShotAlarm(
    ScheduleOneShotAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    if (state.authStatus != 'Granted') {
      final granted = await _repository.requestAuthorization();
      if (!granted) {
        emit(state.copyWith(
          authStatus: 'Denied',
          scheduleStatus: 'Please grant alarm permission in Settings',
        ));
        return;
      }
      emit(state.copyWith(authStatus: 'Granted'));
    }

    emit(state.copyWith(
      scheduleStatus: 'Scheduling...',
      lastAlarmId: null,
    ));

    try {
      final alarmId = await _repository.scheduleOneShotAlarm(
        timestamp: event.timestamp,
        label: event.label,
        tintColor: event.tintColor,
      );

      emit(state.copyWith(
        scheduleStatus: 'Alarm scheduled!',
        lastAlarmId: alarmId,
      ));
    } catch (e) {
      String status = 'Error: $e';
      if (e.toString().contains('UNSUPPORTED_VERSION')) {
        status = 'iOS 26.0+ required';
      } else if (e.toString().contains('NOT_AUTHORIZED')) {
        status = 'Authorization failed: $e';
        emit(state.copyWith(authStatus: 'Unknown'));
      } else if (e.toString().contains('AUTH_ERROR')) {
        status = 'Authorization error: $e';
        emit(state.copyWith(authStatus: 'Error'));
      }

      emit(state.copyWith(scheduleStatus: status));
    }
  }

  Future<void> _onScheduleCountdownAlarm(
    ScheduleCountdownAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    if (state.authStatus != 'Granted') {
      final granted = await _repository.requestAuthorization();
      if (!granted) {
        emit(state.copyWith(
          authStatus: 'Denied',
          scheduleStatus: 'Please grant alarm permission in Settings',
        ));
        return;
      }
      emit(state.copyWith(authStatus: 'Granted'));
    }

    emit(state.copyWith(
      scheduleStatus: 'Scheduling...',
      lastAlarmId: null,
    ));

    try {
      final alarmId = await _repository.scheduleCountdownAlarm(
        countdownDurationInSeconds: event.countdownDurationInSeconds,
        repeatDurationInSeconds: event.repeatDurationInSeconds,
        label: event.label,
        tintColor: event.tintColor,
      );

      emit(state.copyWith(
        scheduleStatus: 'Alarm scheduled!',
        lastAlarmId: alarmId,
      ));
    } catch (e) {
      emit(state.copyWith(scheduleStatus: 'Error: $e'));
    }
  }

  Future<void> _onCancelAlarm(
    CancelAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    final canceled = await _repository.cancelAlarm(alarmId: event.alarmId);
    emit(state.copyWith(scheduleStatus: canceled ? 'Alarm canceled' : 'Error'));
  }

  Future<void> _onStopAlarm(
    StopAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    final stopped = await _repository.stopAlarm(alarmId: event.alarmId);
    emit(state.copyWith(scheduleStatus: stopped ? 'Alarm stopped' : 'Error'));
  }
}
