import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarm_bloc.dart';
import 'status_container.dart';

class AuthSection extends StatelessWidget {
  const AuthSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlarmBloc, AlarmState>(
      builder: (context, state) {
        return Column(
          children: [
            const Text(
              'Alarm Permission Status:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StatusContainer(
              text: state.authStatus,
              color: _getStatusColor(state.authStatus),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<AlarmBloc>().add(RequestAuthorization());
              },
              child: const Text('Request Alarm Permission'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
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
}
