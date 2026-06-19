import 'package:flutter/cupertino.dart';
import '../log_controller.dart';

/// A scrollable, monospaced console of captured logs with a clear button.
class LogPanel extends StatelessWidget {
  const LogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'LOGS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: logController.clear,
                child: const Text('Clear', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 200,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoColors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ValueListenableBuilder<List<String>>(
              valueListenable: logController,
              builder: (context, lines, _) {
                if (lines.isEmpty) {
                  return const Text(
                    'No logs yet.',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 12,
                      fontFamily: 'Menlo',
                    ),
                  );
                }
                return CupertinoScrollbar(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      final line = lines[lines.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          line,
                          style: const TextStyle(
                            color: CupertinoColors.systemGreen,
                            fontSize: 11,
                            fontFamily: 'Menlo',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
