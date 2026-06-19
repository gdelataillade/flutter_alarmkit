import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../log_controller.dart';

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
  final String? soundPath;

  const ScheduleOneShotAlarm({
    required this.timestamp,
    required this.label,
    required this.tintColor,
    this.soundPath,
  });

  @override
  List<Object?> get props => [timestamp, label, tintColor, soundPath];
}

class ScheduleCountdownAlarm extends AlarmEvent {
  final int countdownDurationInSeconds;
  final int repeatDurationInSeconds;
  final String label;
  final String tintColor;
  final String? soundPath;

  const ScheduleCountdownAlarm({
    required this.countdownDurationInSeconds,
    required this.repeatDurationInSeconds,
    required this.label,
    required this.tintColor,
    this.soundPath,
  });

  @override
  List<Object?> get props => [
        countdownDurationInSeconds,
        repeatDurationInSeconds,
        label,
        tintColor,
        soundPath,
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

/// Re-fetches the live alarm list. Dispatched on init and whenever the
/// alarm-updates stream reports a change.
class RefreshAlarms extends AlarmEvent {}

// State
class AlarmState extends Equatable {
  final String platformVersion;
  final String authStatus;
  final String scheduleStatus;
  final String? lastAlarmId;
  final List<Alarm> alarms;

  const AlarmState({
    this.platformVersion = 'Unknown',
    this.authStatus = 'Permission not requested',
    this.scheduleStatus = 'No alarm scheduled',
    this.lastAlarmId,
    this.alarms = const [],
  });

  AlarmState copyWith({
    String? platformVersion,
    String? authStatus,
    String? scheduleStatus,
    String? lastAlarmId,
    List<Alarm>? alarms,
  }) {
    return AlarmState(
      platformVersion: platformVersion ?? this.platformVersion,
      authStatus: authStatus ?? this.authStatus,
      scheduleStatus: scheduleStatus ?? this.scheduleStatus,
      lastAlarmId: lastAlarmId ?? this.lastAlarmId,
      alarms: alarms ?? this.alarms,
    );
  }

  @override
  List<Object?> get props => [
        platformVersion,
        authStatus,
        scheduleStatus,
        lastAlarmId,
        alarms,
      ];
}

// BLoC
class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  final AlarmRepository _repository;
  late final StreamSubscription<AlarmUpdateEvent> _alarmSubscription;

  AlarmBloc(this._repository) : super(const AlarmState()) {
    on<InitializeAlarm>(_onInitialize);
    on<RequestAuthorization>(_onRequestAuthorization);
    on<ScheduleOneShotAlarm>(_onScheduleOneShotAlarm);
    on<ScheduleCountdownAlarm>(_onScheduleCountdownAlarm);
    on<CancelAlarm>(_onCancelAlarm);
    on<StopAlarm>(_onStopAlarm);
    on<RefreshAlarms>(_onRefreshAlarms);

    // Subscribe before the first fetch so no update is missed; any system
    // change re-fetches the authoritative list.
    _alarmSubscription = _repository.watchAlarms().listen(
          (event) {
            final id = event.alarmId;
            final shortId = id.length > 8 ? id.substring(0, 8) : id;
            final stateText =
                event.alarm != null ? ' (${event.alarm!.state.name})' : '';
            logController.log('alarm ${event.kind.name}: $shortId$stateText');
            add(RefreshAlarms());
          },
          onError: (Object error) =>
              logController.log('alarmUpdates error: $error'),
        );
  }

  @override
  Future<void> close() {
    _alarmSubscription.cancel();
    return super.close();
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
    add(RefreshAlarms());
  }

  Future<void> _onRefreshAlarms(
    RefreshAlarms event,
    Emitter<AlarmState> emit,
  ) async {
    try {
      final alarms = await _repository.getAlarms();
      emit(state.copyWith(alarms: alarms));
    } catch (_) {
      // Likely not authorized yet (or iOS < 26); leave the list unchanged.
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
        soundPath: event.soundPath,
      );

      emit(state.copyWith(
        scheduleStatus: 'Alarm scheduled!',
        lastAlarmId: alarmId,
      ));
      add(RefreshAlarms());
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
        soundPath: event.soundPath,
      );

      emit(state.copyWith(
        scheduleStatus: 'Alarm scheduled!',
        lastAlarmId: alarmId,
      ));
      add(RefreshAlarms());
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
    add(RefreshAlarms());
  }

  Future<void> _onStopAlarm(
    StopAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    final stopped = await _repository.stopAlarm(alarmId: event.alarmId);
    emit(state.copyWith(scheduleStatus: stopped ? 'Alarm stopped' : 'Error'));
    add(RefreshAlarms());
  }
}
