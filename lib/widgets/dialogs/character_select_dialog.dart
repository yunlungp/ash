import 'package:flutter/material.dart';
import '../../models/character_unit.dart';
import '../../models/hero_preset.dart';
import '../hexagon_avatar.dart';

/// 角色選擇與先攻設定對話框
class CharacterSelectDialog extends StatefulWidget {
  final int initialStartingPlayer;
  final Function({
    required CharacterUnit hero1,
    required CharacterUnit hero2,
    required int startingPlayerIndex,
  }) onConfirm;

  const CharacterSelectDialog({
    super.key,
    this.initialStartingPlayer = 0,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    int initialStartingPlayer = 0,
    required Function({
      required CharacterUnit hero1,
      required CharacterUnit hero2,
      required int startingPlayerIndex,
    }) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CharacterSelectDialog(
        initialStartingPlayer: initialStartingPlayer,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<CharacterSelectDialog> createState() => _CharacterSelectDialogState();
}

class _CharacterSelectDialogState extends State<CharacterSelectDialog> {
  HeroPreset _p1Selected = HeroPresets.eris;
  HeroPreset _p2Selected = HeroPresets.luna;
  late int _startingPlayerIndex;

  @override
  void initState() {
    super.initState();
    _startingPlayerIndex = widget.initialStartingPlayer;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: const Color(0xFF131822),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2E3D52), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 340),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 頂部標題與先攻選擇
              Row(
                children: [
                  const Icon(Icons.sports_kabaddi, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    '選擇對戰角色與先攻方',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  // 先攻切換鈕
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '先攻: ',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        ChoiceChip(
                          label: const Text('P1 (藍)'),
                          selected: _startingPlayerIndex == 0,
                          onSelected: (val) {
                            if (val) setState(() => _startingPlayerIndex = 0);
                          },
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _startingPlayerIndex == 0 ? Colors.white : Colors.white60,
                          ),
                          selectedColor: const Color(0xFF3B82F6),
                          backgroundColor: Colors.transparent,
                        ),
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text('P2 (紅)'),
                          selected: _startingPlayerIndex == 1,
                          onSelected: (val) {
                            if (val) setState(() => _startingPlayerIndex = 1);
                          },
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _startingPlayerIndex == 1 ? Colors.white : Colors.white60,
                          ),
                          selectedColor: const Color(0xFFEF4444),
                          backgroundColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 角色選擇區：左邊 P1 | 右邊 P2
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Player 1 角色選擇卡
                    Expanded(
                      child: _buildPlayerSelector(
                        playerIndex: 0,
                        title: 'Player 1 (藍方)',
                        themeColor: const Color(0xFF3B82F6),
                        selectedPreset: _p1Selected,
                        onSelect: (p) => setState(() => _p1Selected = p),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Player 2 角色選擇卡
                    Expanded(
                      child: _buildPlayerSelector(
                        playerIndex: 1,
                        title: 'Player 2 (紅方)',
                        themeColor: const Color(0xFFEF4444),
                        selectedPreset: _p2Selected,
                        onSelect: (p) => setState(() => _p2Selected = p),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 底部確認開始對戰按鈕
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final h1 = _p1Selected.toCharacterUnit(
                      ownerIndex: 0,
                      customDisplayName: _p1Selected.name,
                    );
                    final h2 = _p2Selected.toCharacterUnit(
                      ownerIndex: 1,
                      customDisplayName: _p2Selected.name,
                    );

                    Navigator.of(context).pop();

                    widget.onConfirm(
                      hero1: h1,
                      hero2: h2,
                      startingPlayerIndex: _startingPlayerIndex,
                    );
                  },
                  icon: const Icon(Icons.play_arrow, size: 20, color: Colors.black),
                  label: const Text(
                    '確認出戰！開始對決',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSelector({
    required int playerIndex,
    required String title,
    required Color themeColor,
    required HeroPreset selectedPreset,
    required ValueChanged<HeroPreset> onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF18202D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withAlpha(120), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 標題
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: themeColor),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '目前: ${selectedPreset.name}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 3 個頭像選擇列表（Eris, Luna, Custom）
          Expanded(
            child: Row(
              children: HeroPresets.all.map((preset) {
                final isSelected = selectedPreset.id == preset.id;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Tooltip(
                      message: '長按或點擊查看【${preset.name}】詳細數值\n${preset.description}',
                      child: InkWell(
                        onTap: () => onSelect(preset),
                        onLongPress: () => _showStatDetailDialog(context, preset),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? themeColor.withAlpha(45) : const Color(0xFF121721),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? themeColor : const Color(0xFF2A364A),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HexagonAvatar(
                                imageAsset: preset.avatarAsset,
                                size: 48,
                                borderColor: isSelected ? themeColor : Colors.white30,
                                borderWidth: isSelected ? 2.5 : 1.5,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preset.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // 底部即時顯示目前所選角色的能力值條（HP, ATK, RNG, MOV）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10141D),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statMiniBadge('HP', '${selectedPreset.hp}', Colors.redAccent),
                _statMiniBadge('ATK', '${selectedPreset.atk}', Colors.orangeAccent),
                _statMiniBadge('RNG', '${selectedPreset.range}', Colors.cyanAccent),
                _statMiniBadge('MOV', '${selectedPreset.move}', Colors.lightGreenAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statMiniBadge(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showStatDetailDialog(BuildContext context, HeroPreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2532),
        title: Row(
          children: [
            HexagonAvatar(
              imageAsset: preset.avatarAsset,
              size: 40,
              borderColor: Colors.amberAccent,
            ),
            const SizedBox(width: 10),
            Text(
              '${preset.name} - 角色能力值',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• 生命值 (HP): ${preset.hp}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('• 攻擊力 (ATK): ${preset.atk}',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('• 攻擊範圍 (RNG): ${preset.range}',
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('• 移動距離 (MOV): ${preset.move}',
                style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(preset.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('了解', style: TextStyle(color: Colors.amberAccent)),
          ),
        ],
      ),
    );
  }
}
