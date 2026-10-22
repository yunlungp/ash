import 'package:flutter/material.dart';

class GameOverDialog extends StatelessWidget {
  final int? winnerIndex; // 0: P1, 1: P2, -1: 平手, null: 手動結束
  final String title;
  final String reason;
  final VoidCallback onRestart;

  const GameOverDialog({
    super.key,
    required this.winnerIndex,
    required this.title,
    required this.reason,
    required this.onRestart,
  });

  static Future<void> show({
    required BuildContext context,
    required int? winnerIndex,
    required String title,
    required String reason,
    required VoidCallback onRestart,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        winnerIndex: winnerIndex,
        title: title,
        reason: reason,
        onRestart: onRestart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor;
    IconData iconData;

    if (winnerIndex == 0) {
      themeColor = Colors.blueAccent;
      iconData = Icons.emoji_events;
    } else if (winnerIndex == 1) {
      themeColor = Colors.redAccent;
      iconData = Icons.emoji_events;
    } else if (winnerIndex == -1) {
      themeColor = Colors.amberAccent;
      iconData = Icons.handshake;
    } else {
      themeColor = Colors.orangeAccent;
      iconData = Icons.flag;
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: const Color(0xFF1E2430),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: themeColor, width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor.withAlpha(40),
                    border: Border.all(color: themeColor, width: 2),
                  ),
                  child: Icon(iconData, size: 36, color: themeColor),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('檢視戰局盤面', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRestart();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('重新開始新對戰', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
