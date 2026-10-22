import 'package:flutter/material.dart';
import '../../models/character_unit.dart';
import 'arithmetic_input_dialog.dart';

/// 專門設定單位能量值系統 (Energy) 的彈窗
class EnergyConfigDialog extends StatefulWidget {
  final CharacterUnit unit;
  final Function({
    required bool enabled,
    int? currentEnergy,
    int? energyPerTurnDelta,
    int? minEnergy,
    int? maxEnergy,
  }) onSave;

  const EnergyConfigDialog({
    super.key,
    required this.unit,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required CharacterUnit unit,
    required Function({
      required bool enabled,
      int? currentEnergy,
      int? energyPerTurnDelta,
      int? minEnergy,
      int? maxEnergy,
    }) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => EnergyConfigDialog(unit: unit, onSave: onSave),
    );
  }

  @override
  State<EnergyConfigDialog> createState() => _EnergyConfigDialogState();
}

class _EnergyConfigDialogState extends State<EnergyConfigDialog> {
  late bool _enabled;
  late int _currentEnergy;
  late int _energyPerTurnDelta;
  late int _minEnergy;
  late int _maxEnergy;

  @override
  void initState() {
    super.initState();
    final unit = widget.unit;
    _enabled = unit.currentEnergy != null;
    _currentEnergy = unit.currentEnergy ?? 0;
    _energyPerTurnDelta = unit.energyPerTurnDelta;
    _minEnergy = unit.minEnergy;
    _maxEnergy = unit.maxEnergy;
  }

  void _save() {
    widget.onSave(
      enabled: _enabled,
      currentEnergy: _currentEnergy,
      energyPerTurnDelta: _energyPerTurnDelta,
      minEnergy: _minEnergy,
      maxEnergy: _maxEnergy,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: const Color(0xFF1E2430),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF4A3860), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: screenHeight * 0.94,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 頂部標題列
              Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.purpleAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.unit.name} - 能量值 (EN) 設定',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF334055), height: 10),

              // 可滾動內容區，避免橫屏或鍵盤開啟時 overflow
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 啟用開關列
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141923),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _enabled ? Colors.purpleAccent.withAlpha(120) : const Color(0xFF2C384C),
                            width: _enabled ? 1.2 : 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.power_settings_new, color: Colors.purpleAccent, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              '啟用能量值系統',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: _enabled,
                                activeThumbColor: Colors.purpleAccent,
                                activeTrackColor: Colors.purpleAccent.withAlpha(100),
                                onChanged: (val) {
                                  setState(() => _enabled = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_enabled) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _stepperWidget(
                                label: '當前/初始能量',
                                value: _currentEnergy,
                                color: Colors.purpleAccent,
                                onChanged: (v) => setState(() => _currentEnergy = v),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _stepperWidget(
                                label: '每回合能量 (+/-)',
                                value: _energyPerTurnDelta,
                                color: Colors.deepPurpleAccent,
                                onChanged: (v) => setState(() => _energyPerTurnDelta = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _stepperWidget(
                                label: '最小能量 (下限)',
                                value: _minEnergy,
                                color: Colors.blueAccent,
                                onChanged: (v) => setState(() => _minEnergy = v),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _stepperWidget(
                                label: '最大能量 (上限)',
                                value: _maxEnergy,
                                color: Colors.amberAccent,
                                onChanged: (v) => setState(() => _maxEnergy = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 底部按鈕
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('確認儲存', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepperWidget({
    required String label,
    required int value,
    required Color color,
    required Function(int) onChanged,
    bool allowNegative = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C384C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 14, color: Colors.white60),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => onChanged(value - 1),
              ),
              InkWell(
                onTap: () {
                  ArithmeticInputDialog.showCustom(
                    context: context,
                    title: label,
                    currentValue: value,
                    allowNegative: allowNegative,
                    onConfirmValue: (newVal) => onChanged(newVal),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withAlpha(90), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value > 0 ? '+$value' : '$value',
                        style: TextStyle(
                          color: value != 0 ? color : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.edit, size: 10, color: color.withAlpha(190)),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 14, color: Colors.white60),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
