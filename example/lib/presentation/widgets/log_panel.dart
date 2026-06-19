import 'package:flutter/cupertino.dart';

import '../example_theme.dart';
import '../log_controller.dart';

/// A collapsible, monospaced console of captured plugin logs.
class LogPanel extends StatefulWidget {
  const LogPanel({super.key});

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ExampleTheme.cardDecoration(context),
      child: Column(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            minimumSize: const Size(double.infinity, 52),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(CupertinoIcons.chevron_left_slash_chevron_right,
                    size: 19),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Plugin logs',
                    style: TextStyle(
                      color: CupertinoColors.label,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: logController,
                  builder: (context, lines, _) => Text(
                    '${lines.length}',
                    style: const TextStyle(
                      color: ExampleTheme.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  color: ExampleTheme.secondaryText,
                  size: 16,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            Container(
              height: 1,
              color: ExampleTheme.resolve(context, ExampleTheme.border),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      minimumSize: const Size(0, 30),
                      onPressed: logController.clear,
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111418),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ValueListenableBuilder<List<String>>(
                      valueListenable: logController,
                      builder: (context, lines, _) {
                        if (lines.isEmpty) {
                          return const Center(
                            child: Text(
                              'No log output yet',
                              style: TextStyle(
                                color: Color(0xFF7F8994),
                                fontSize: 12,
                                fontFamily: 'Menlo',
                              ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  line,
                                  style: const TextStyle(
                                    color: Color(0xFFD1D7DE),
                                    fontSize: 11,
                                    height: 1.35,
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
            ),
          ],
        ],
      ),
    );
  }
}
