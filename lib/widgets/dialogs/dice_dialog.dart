import 'dart:math' as math;
import 'package:flutter/material.dart';

class DiceDialog extends StatefulWidget {
  final Function(int sides, int result) onRoll;

  const DiceDialog({super.key, required this.onRoll});

  static Future<void> show({
    required BuildContext context,
    required Function(int sides, int result) onRoll,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DiceDialog(onRoll: onRoll),
    );
  }

  @override
  State<DiceDialog> createState() => _DiceDialogState();
}

class _DiceDialogState extends State<DiceDialog> with SingleTickerProviderStateMixin {
  int _selectedSides = 6;
  int? _currentResult;
  bool _isRolling = false;
  late AnimationController _animController;

  final List<int> _diceOptions = [4, 6, 8, 10, 12, 20, 100];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _roll() async {
    if (_isRolling) return;
    setState(() {
      _isRolling = true;
    });

    _animController.forward(from: 0.0);

    // 擲骰子擬真跳動效果
    for (int i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;
      setState(() {
        _currentResult = math.Random().nextInt(_selectedSides) + 1;
      });
    }

    final finalResult = math.Random().nextInt(_selectedSides) + 1;
    if (!mounted) return;
    setState(() {
      _currentResult = finalResult;
      _isRolling = false;
    });

    widget.onRoll(_selectedSides, finalResult);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: const Color(0xFF1E2430),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3B4860), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: math.min(310.0, screenHeight * 0.94),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左側：選擇種類
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.yellowAccent.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.casino, color: Colors.yellowAccent, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '擲骰子 (Roll Dice)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF334055), height: 12),
                      const Text(
                        '選擇骰子類型：',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _diceOptions.map((sides) {
                          final isSelected = _selectedSides == sides;
                          return ChoiceChip(
                            label: Text('D$sides'),
                            selected: isSelected,
                            selectedColor: Colors.yellowAccent,
                            backgroundColor: const Color(0xFF141923),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? Colors.yellowAccent : const Color(0xFF334055),
                                width: 1.2,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedSides = sides;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // 右側：骰子與按鈕
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      // 骰子顯示區
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animController.value * 2 * math.pi,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF141923),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _currentResult != null
                                      ? Colors.yellowAccent
                                      : const Color(0xFF3A475C),
                                  width: 2,
                                ),
                                boxShadow: [
                                  if (_currentResult != null)
                                    BoxShadow(
                                      color: Colors.yellowAccent.withAlpha(50),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _currentResult != null ? '$_currentResult' : '?',
                                style: TextStyle(
                                  color: _currentResult != null
                                      ? Colors.yellowAccent
                                      : Colors.white38,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // 擲骰按鈕 (高度 40px，字體 14px，大熱區)
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _isRolling ? null : _roll,
                          icon: const Icon(Icons.casino, size: 18),
                          label: Text(
                            _isRolling ? '搖晃中...' : '甩 D$_selectedSides 骰子！',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellowAccent.shade700,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
