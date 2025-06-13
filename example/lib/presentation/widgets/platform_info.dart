import 'package:flutter/material.dart';

class PlatformInfo extends StatelessWidget {
  final String platformVersion;

  const PlatformInfo({
    super.key,
    required this.platformVersion,
  });

  @override
  Widget build(BuildContext context) {
    return Text('Running on: $platformVersion');
  }
}
