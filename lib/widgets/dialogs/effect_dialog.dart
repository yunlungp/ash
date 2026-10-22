import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/character_unit.dart';
import '../../models/status_effect.dart';
import 'arithmetic_input_dialog.dart';

class EffectDialog extends StatefulWidget {
  final CharacterUnit unit;
  final StatusEffect? initialEffect; // 若不為空則為編輯模式
  final Function(StatusEffect effect)? onSave;
  final VoidCallback? onDelete;

  const EffectDialog({
    super.key,
    required this.unit,
    this.initialEffect,
    this.onSave,
    this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required CharacterUnit unit,
    StatusEffect? initialEffect,
    Function(StatusEffect effect)? onSave,
    VoidCallback? onDelete,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => EffectDialog(
        unit: unit,
        initialEffect: initialEffect,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<EffectDialog> createState() => _EffectDialogState();
}

class _EffectDialogState extends State<EffectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedIcon;
  late int _shieldDelta;
  late int _atkDelta;
  late int _rangeDelta;
  late int _moveDelta;
  late int _hpPerTurnDelta;
  late int _turnsRemaining;
  late bool _isPermanent;
  late bool _isDebuff;

  // 預設效果模板
  final List<StatusEffect> _presets = [
    const StatusEffect(
      id: 'preset_shield_buff',
      name: '堅固護盾',
      iconCode: 'shield',
      shieldDelta: 10,
      turnsRemaining: 2,
      isDebuff: false,
      description: '提供 10 點額外臨時護盾',
    ),
    const StatusEffect(
      id: 'preset_berserk',
      name: '狂暴',
      iconCode: 'sword',
      atkDelta: 5,
      turnsRemaining: 2,
      isDebuff: false,
      description: '攻擊力暫時提升 5 點',
    ),
    const StatusEffect(
      id: 'preset_shield',
      name: '神聖護盾',
      iconCode: 'shield',
      shieldDelta: 20,
      atkDelta: 0,
      isPermanent: true,
      isDebuff: false,
      description: '受到神聖庇護，永久增加 20 點護盾',
    ),
    const StatusEffect(
      id: 'preset_regen',
      name: '生命再生',
      iconCode: 'heal',
      hpPerTurnDelta: 5,
      turnsRemaining: 3,
      isDebuff: false,
      description: '每回合結束時恢復 5 點生命',
    ),
    const StatusEffect(
      id: 'preset_speed',
      name: '神速奔馳',
      iconCode: 'speed',
      moveDelta: 2,
      turnsRemaining: 2,
      isDebuff: false,
      description: '移動距離暫時增加 2 點',
    ),
    const StatusEffect(
      id: 'preset_eagle',
      name: '鷹眼狙擊',
      iconCode: 'star',
      rangeDelta: 2,
      turnsRemaining: 2,
      isDebuff: false,
      description: '攻擊範圍擴大 2 格',
    ),
    const StatusEffect(
      id: 'preset_shield_break',
      name: '破甲詛咒',
      iconCode: 'skull',
      shieldDelta: -10,
      turnsRemaining: 2,
      isDebuff: true,
      description: '削弱目標 10 點護盾',
    ),
    const StatusEffect(
      id: 'preset_poison',
      name: '劇毒侵蝕',
      iconCode: 'poison',
      hpPerTurnDelta: -5,
      turnsRemaining: 3,
      isDebuff: true,
      description: '每回合結束扣除 5 點生命',
    ),
    const StatusEffect(
      id: 'preset_burn',
      name: '烈焰燃燒',
      iconCode: 'fire',
      hpPerTurnDelta: -3,
      atkDelta: -2,
      turnsRemaining: 2,
      isDebuff: true,
      description: '每回合扣除 3 點生命且降低 2 點攻擊力',
    ),
    const StatusEffect(
      id: 'preset_slow',
      name: '寒冰遲緩',
      iconCode: 'freeze',
      moveDelta: -1,
      rangeDelta: -1,
      turnsRemaining: 2,
      isDebuff: true,
      description: '移動距離與攻擊範圍各減少 1',
    ),
    const StatusEffect(
      id: 'preset_blind',
      name: '致盲黑暗',
      iconCode: 'blind',
      rangeDelta: -2,
      turnsRemaining: 2,
      isDebuff: true,
      description: '攻擊範圍大幅受限 -2',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialEffect;
    if (init != null) {
      _nameController = TextEditingController(text: init.name);
      _descController = TextEditingController(text: init.description);
      _selectedIcon = init.iconCode;
      _shieldDelta = init.shieldDelta;
      _atkDelta = init.atkDelta;
      _rangeDelta = init.rangeDelta;
      _moveDelta = init.moveDelta;
      _hpPerTurnDelta = init.hpPerTurnDelta;
      _turnsRemaining = init.turnsRemaining;
      _isPermanent = init.isPermanent;
      _isDebuff = init.isDebuff;
    } else {
      _nameController = TextEditingController(text: '');
      _descController = TextEditingController(text: '');
      _selectedIcon = 'sword';
      _shieldDelta = 0;
      _atkDelta = 0;
      _rangeDelta = 0;
      _moveDelta = 0;
      _hpPerTurnDelta = 0;
      _turnsRemaining = 2;
      _isPermanent = false;
      _isDebuff = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _applyPreset(StatusEffect p) {
    setState(() {
      _nameController.text = p.name;
      _descController.text = p.description;
      _selectedIcon = p.iconCode;
      _shieldDelta = p.shieldDelta;
      _atkDelta = p.atkDelta;
      _rangeDelta = p.rangeDelta;
      _moveDelta = p.moveDelta;
      _hpPerTurnDelta = p.hpPerTurnDelta;
      _turnsRemaining = p.turnsRemaining;
      _isPermanent = p.isPermanent;
      _isDebuff = p.isDebuff;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫效果名稱')),
      );
      return;
    }

    final effect = StatusEffect(
      id: widget.initialEffect?.id ??
          'effect_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      iconCode: _selectedIcon,
      shieldDelta: _shieldDelta,
      atkDelta: _atkDelta,
      rangeDelta: _rangeDelta,
      moveDelta: _moveDelta,
      hpPerTurnDelta: _hpPerTurnDelta,
      turnsRemaining: _turnsRemaining,
      isPermanent: _isPermanent,
      isDebuff: _isDebuff,
      description: _descController.text.trim(),
    );

    widget.onSave?.call(effect);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialEffect != null;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogMaxHeight = math.min(350.0, screenHeight * 0.94);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: const Color(0xFF1E2430),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3B4860), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 660, maxHeight: dialogMaxHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              // 頂部標題列
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.auto_awesome,
                    color: _isDebuff ? Colors.redAccent : Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing
                          ? '編輯狀態效果 • ${widget.unit.name}'
                          : '添加狀態效果 • ${widget.unit.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const Divider(color: Color(0xFF334055), height: 8),

              // 主體左右兩欄 (橫屏最佳化：縮減預設模板比例，讓詳細自訂設定更寬裕)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左側：預設模板列表 (flex 由 4 降至 3，收縮寬度)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '預設模板',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Material(
                              color: const Color(0xFF141923),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF2C384C)),
                                ),
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  itemCount: _presets.length,
                                  separatorBuilder: (ctx, i) =>
                                      const Divider(color: Color(0xFF222B3B), height: 1),
                                  itemBuilder: (ctx, i) {
                                    final p = _presets[i];
                                    final isSelected = _nameController.text == p.name;
                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      selected: isSelected,
                                      selectedTileColor: p.isDebuff
                                          ? Colors.red.withAlpha(50)
                                          : Colors.amber.withAlpha(50),
                                      leading: Icon(
                                        p.iconData,
                                        size: 16,
                                        color: p.color,
                                      ),
                                      title: Text(
                                        p.name,
                                        style: TextStyle(
                                          color: p.color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        p.effectSummary,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 9,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => _applyPreset(p),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 右側：詳細自訂屬性設定 (flex 提升至 7，獲得更大編輯空間)
                    Expanded(
                      flex: 7,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 效果名稱與類型
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: '效果名稱',
                                      labelStyle: const TextStyle(fontSize: 12, color: Colors.white60),
                                      isDense: true,
                                      filled: true,
                                      fillColor: const Color(0xFF141923),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 正面/負面切換
                                Expanded(
                                  flex: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isDebuff = !_isDebuff;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _isDebuff
                                            ? Colors.redAccent.withAlpha(40)
                                            : Colors.greenAccent.withAlpha(40),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _isDebuff ? Colors.redAccent : Colors.greenAccent,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _isDebuff ? '負面 Debuff' : '正面 Buff',
                                        style: TextStyle(
                                          color: _isDebuff ? Colors.redAccent : Colors.greenAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // 圖示快選
                            Row(
                              children: [
                                const Text('圖示: ', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _iconOption('sword', Icons.sports_kabaddi),
                                        _iconOption('shield', Icons.shield),
                                        _iconOption('speed', Icons.speed),
                                        _iconOption('star', Icons.star),
                                        _iconOption('heal', Icons.favorite),
                                        _iconOption('poison', Icons.science),
                                        _iconOption('fire', Icons.local_fire_department),
                                        _iconOption('freeze', Icons.ac_unit),
                                        _iconOption('blind', Icons.visibility_off),
                                        _iconOption('skull', Icons.coronavirus),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // 屬性數值加減調整器 (Shield, ATK, Range, Move, HP/回合)
                            Row(
                              children: [
                                Expanded(
                                  child: _stepperWidget(
                                    label: '護盾 Shield 增減',
                                    value: _shieldDelta,
                                    color: Colors.blue.shade300,
                                    onChanged: (v) => setState(() => _shieldDelta = v),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _stepperWidget(
                                    label: 'ATK 攻擊力 增減',
                                    value: _atkDelta,
                                    color: Colors.orangeAccent,
                                    onChanged: (v) => setState(() => _atkDelta = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _stepperWidget(
                                    label: 'Range 範圍 增減',
                                    value: _rangeDelta,
                                    color: Colors.cyanAccent,
                                    onChanged: (v) => setState(() => _rangeDelta = v),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _stepperWidget(
                                    label: 'Move 移動 增減',
                                    value: _moveDelta,
                                    color: Colors.lightGreenAccent,
                                    onChanged: (v) => setState(() => _moveDelta = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _stepperWidget(
                              label: 'HP/回合 (負數毒燒 / 正數再生)',
                              value: _hpPerTurnDelta,
                              color: Colors.pinkAccent,
                              onChanged: (v) => setState(() => _hpPerTurnDelta = v),
                            ),

                            const SizedBox(height: 8),

                            // 持續回合與永久切換
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141923),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    '永久效果',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                  Switch(
                                    value: _isPermanent,
                                    activeThumbColor: Colors.amber,
                                    activeTrackColor: Colors.amber.withAlpha(100),
                                    onChanged: (val) {
                                      setState(() {
                                        _isPermanent = val;
                                      });
                                    },
                                  ),
                                  const Spacer(),
                                  if (!_isPermanent) ...[
                                    const Text(
                                      '持續回合: ',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline,
                                          color: Colors.white70, size: 16),
                                      onPressed: _turnsRemaining > 1
                                          ? () => setState(() => _turnsRemaining--)
                                          : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        ArithmeticInputDialog.showCustom(
                                          context: context,
                                          title: '設定效果持續回合數',
                                          currentValue: _turnsRemaining,
                                          allowNegative: false,
                                          onConfirmValue: (newVal) {
                                            if (newVal < 1) newVal = 1;
                                            setState(() => _turnsRemaining = newVal);
                                          },
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withAlpha(25),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.amber.withAlpha(90), width: 0.8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '$_turnsRemaining 回合',
                                              style: const TextStyle(
                                                color: Colors.amberAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            const Icon(Icons.edit, size: 10, color: Colors.amberAccent),
                                          ],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          color: Colors.white70, size: 16),
                                      onPressed: () => setState(() => _turnsRemaining++),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ] else ...[
                                    const Text(
                                      '∞ 永久生效 (不隨回合倒數)',
                                      style: TextStyle(
                                        color: Colors.amberAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 底部按鈕
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isEditing && widget.onDelete != null) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        widget.onDelete?.call();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      label: const Text('刪除此效果', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isEditing ? '儲存修改' : '掛載效果',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconOption(String code, IconData icon) {
    final isSelected = _selectedIcon == code;
    return InkWell(
      onTap: () => setState(() => _selectedIcon = code),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withAlpha(50) : const Color(0xFF141923),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.amber : const Color(0xFF2C384C),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Icon(icon, size: 16, color: isSelected ? Colors.amber : Colors.white60),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF253042)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
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
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }
}
