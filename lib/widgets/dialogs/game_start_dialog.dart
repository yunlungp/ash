import 'package:flutter/material.dart';

class GameStartDialog extends StatefulWidget {
  final int initialSelectedIndex;
  final Function(int selectedPlayerIndex) onConfirm;

  const GameStartDialog({
    super.key,
    this.initialSelectedIndex = 0,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    int initialSelectedIndex = 0,
    required Function(int selectedPlayerIndex) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameStartDialog(
        initialSelectedIndex: initialSelectedIndex,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<GameStartDialog> createState() => _GameStartDialogState();
}

class _GameStartDialogState extends State<GameStartDialog> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: const Color(0xFF1E2430),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3B4860), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withAlpha(30),
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: const Icon(Icons.sports_esports, color: Colors.amber, size: 28),
                ),
                const SizedBox(height: 8),
                const Text(
                  '選擇先攻方 (First Turn)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '請選擇這場桌遊由哪一位玩家先開始行動：',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // 選擇按鈕
                Row(
                  children: [
                    Expanded(
                      child: _playerOption(
                        index: 0,
                        title: '玩家 1 (藍方)',
                        subtitle: '左方玩家先攻',
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _playerOption(
                        index: 1,
                        title: '玩家 2 (紅方)',
                        subtitle: '右方玩家先攻',
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(_selectedIndex);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      '確認開始對戰！',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playerOption({
    required int index,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(40) : const Color(0xFF141923),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF2C384C),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? color : Colors.white38,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
