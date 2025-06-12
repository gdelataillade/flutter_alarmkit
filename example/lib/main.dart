import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _authStatus = 'Not requested';
  String _scheduleStatus = 'No alarm scheduled';
  String? _lastAlarmId;
  final _flutterAlarmkitPlugin = FlutterAlarmkit();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _flutterAlarmkitPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _requestAuthorization() async {
    setState(() {
      _authStatus = 'Requesting...';
    });

    try {
      final bool granted = await _flutterAlarmkitPlugin.requestAuthorization();
      if (!mounted) return;

      setState(() {
        _authStatus = granted ? 'Granted' : 'Denied';
      });
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED_VERSION') {
        _authStatus = 'iOS 26.0+ required';
      }
      if (!mounted) return;

      setState(() {
        _authStatus = 'Error: ${e.message}';
      });
    }
  }

  Future<void> _scheduleTestAlarm() async {
    setState(() {
      _scheduleStatus = 'Scheduling...';
      _lastAlarmId = null;
    });

    try {
      // First ensure we have authorization
      if (_authStatus != 'Granted') {
        final granted = await _flutterAlarmkitPlugin.requestAuthorization();

        if (!mounted) return;

        if (!granted) {
          setState(() {
            _authStatus = 'Denied';
            _scheduleStatus = 'Please grant alarm permission in Settings';
          });
          return;
        }

        setState(() {
          _authStatus = 'Granted';
        });
      }

      // Schedule alarm for 5 seconds from now
      final timestamp =
          DateTime.now()
              .add(const Duration(seconds: 5))
              .millisecondsSinceEpoch
              .toDouble();

      final alarmId = await _flutterAlarmkitPlugin.scheduleOneShotAlarm(
        timestamp: timestamp,
        label: 'Test Alarm',
      );

      if (!mounted) return;

      setState(() {
        _scheduleStatus = 'Alarm scheduled!';
        _lastAlarmId = alarmId;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;

      setState(() {
        switch (e.code) {
          case 'UNSUPPORTED_VERSION':
            _scheduleStatus = 'iOS 26.0+ required';
          case 'NOT_AUTHORIZED':
            _scheduleStatus = 'Authorization failed: ${e.message}';
            // Force a refresh of the authorization state
            _authStatus = 'Unknown';
          case 'AUTH_ERROR':
            _scheduleStatus = 'Authorization error: ${e.message}';
            _authStatus = 'Error';
          default:
            _scheduleStatus = 'Error: ${e.message}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AlarmKit Example')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Running on: $_platformVersion'),
                const SizedBox(height: 20),
                const Text(
                  'Alarm Permission Status:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _authStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _requestAuthorization,
                  child: const Text('Request Alarm Permission'),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Test Alarm:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getScheduleStatusColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _scheduleStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_lastAlarmId != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'ID: $_lastAlarmId',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      _authStatus == 'Granted' ? _scheduleTestAlarm : null,
                  child: const Text('Schedule Test Alarm (5s)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_authStatus) {
      case 'Granted':
        return Colors.green;
      case 'Denied':
        return Colors.red;
      case 'Requesting...':
        return Colors.orange;
      case 'iOS 26.0+ required':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getScheduleStatusColor() {
    if (_scheduleStatus == 'Alarm scheduled!') {
      return Colors.green;
    } else if (_scheduleStatus == 'Scheduling...') {
      return Colors.orange;
    } else if (_scheduleStatus.startsWith('Error') ||
        _scheduleStatus == 'iOS 26.0+ required' ||
        _scheduleStatus == 'Please grant alarm permission first') {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
