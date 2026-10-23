import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_unit.dart';
import '../models/status_effect.dart';
import '../providers/battle_provider.dart';
import '../utils/ui_scale.dart';
import 'dialogs/arithmetic_input_dialog.dart';
import 'dialogs/effect_dialog.dart';
import 'dialogs/energy_config_dialog.dart';
import 'hexagon_avatar.dart';

class UnitCard extends StatelessWidget {
  final CharacterUnit unit;
  final bool isPlayer1;
  final bool isCompact; // 若為小兵卡片使用精簡模式

  const UnitCard({
    super.key,
    required this.unit,
    required this.isPlayer1,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BattleProvider>();
    final isHero = unit.isHero;
    // 依據原始建立者決定 header 和 icon 顏色（移動後小兵仍保留原本顏色）
    final originColor = unit.originalOwnerIndex == 0
        ? const Color(0xFF3B82F6)
        : const Color(0xFFEF4444);
    // 外邊框顏色以所在位置玩家為主，英雄則更加明亮
    final slotOwnerColor = isPlayer1 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A212D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHero
              ? slotOwnerColor.withAlpha(160)
              : originColor.withAlpha(110),
          width: isHero ? 1.4 : 1.1,
        ),
        boxShadow: [
          if (isHero)
            BoxShadow(
              color: slotOwnerColor.withAlpha(25),
              blurRadius: 6,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // 頂部卡片標題列 (使用原始創立時的顏色 originColor)
          _buildHeader(context, provider, originColor),

          // 核心數值展示與快速運算點擊區
          if (isCompact)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: _buildStatsGrid(context, provider),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: _buildStatsGrid(context, provider),
            ),

          // 外圍掛載效果 (Buffs & Debuffs) 晶片列表
          _buildEffectsSection(context, provider),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BattleProvider provider, Color primaryColor) {
    if (unit.isHero) {
      // Player 英雄 Header：顯示六邊形頭像、名字、添加效果
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: primaryColor.withAlpha(30),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
          border: Border(bottom: BorderSide(color: primaryColor.withAlpha(50))),
        ),
        child: Row(
          children: [
            // 六邊形角色頭像
            HexagonAvatar(
              imageAsset: unit.avatarAsset,
              size: 26,
              borderColor: primaryColor,
              borderWidth: 1.5,
              fallbackChild: Icon(Icons.shield, size: 14, color: primaryColor),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: InkWell(
                onTap: () => _showAllEffectsDialog(context, provider),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          unit.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.info_outline, size: 11, color: Colors.white38),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 小兵 (Minion) Header：
    // 1. 移除換位置 icon
    // 2. 名字左邊換成顯示這是 player 生成的第幾個小兵的數字 icon (spawnOrder)
    // 3. 刪除 icon 移回和名字同一排
    // 4. 小兵名字完整顯示
    final minionOrder = unit.spawnOrder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(25),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
        border: Border(bottom: BorderSide(color: primaryColor.withAlpha(50))),
      ),
      child: Row(
        children: [
          // 數字 icon 標籤 (顯示這是該玩家生成的第幾個小兵)
          Container(
            width: 17,
            height: 17,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(70),
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 1.0),
            ),
            child: Text(
              '$minionOrder',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 小兵名字：點擊可查看全部效果並可更改名字
          Expanded(
            child: InkWell(
              onTap: () => _showAllEffectsDialog(context, provider),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  unit.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // 小兵的 level 放在打叉 (X) 的左邊，點擊可直接切換等級
          InkWell(
            onTap: () => _showLevelSelectMenu(context, provider),
            borderRadius: BorderRadius.circular(3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: unit.level != null ? Colors.amber.withAlpha(50) : const Color(0xFF242F42),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: unit.level != null ? Colors.amber : const Color(0xFF3B4A60),
                  width: 0.8,
                ),
              ),
              child: Text(
                unit.level != null ? 'Lv.${unit.level}' : 'Lv.',
                style: TextStyle(
                  color: unit.level != null ? Colors.amberAccent : Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (unit.slotIndex != null) ...[
            const SizedBox(width: 3),
            // 刪除 icon 緊接在 level 右邊
            InkWell(
              onTap: () => _showDismissConfirm(context, provider),
              borderRadius: BorderRadius.circular(3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: const Icon(Icons.close, size: 14, color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, BattleProvider provider) {
    // 護盾項目
    final shieldItem = _buildStatItem(
      context: context,
      provider: provider,
      statType: StatType.shield,
      baseVal: unit.baseShield,
      effectiveVal: unit.effectiveShield,
      bonusVal: unit.buffShieldDelta,
      icon: Icons.shield,
      accentColor: Colors.blue.shade300,
    );

    final hpItem = _buildStatItem(
      context: context,
      provider: provider,
      statType: StatType.hp,
      baseVal: unit.baseHp,
      effectiveVal: unit.effectiveHp,
      bonusVal: 0,
      icon: Icons.favorite,
      accentColor: Colors.redAccent,
    );

    final atkItem = _buildStatItem(
      context: context,
      provider: provider,
      statType: StatType.atk,
      baseVal: unit.baseAtk,
      effectiveVal: unit.effectiveAtk,
      bonusVal: unit.buffAtkDelta + unit.passiveAtkBonus,
      icon: Icons.sports_kabaddi,
      accentColor: Colors.orangeAccent,
    );

    final rangeItem = _buildStatItem(
      context: context,
      provider: provider,
      statType: StatType.range,
      baseVal: unit.baseRange,
      effectiveVal: unit.effectiveRange,
      bonusVal: unit.buffRangeDelta + unit.passiveRangeBonus,
      icon: Icons.radar,
      accentColor: Colors.cyanAccent,
    );

    final moveItem = _buildStatItem(
      context: context,
      provider: provider,
      statType: StatType.move,
      baseVal: unit.baseMove,
      effectiveVal: unit.effectiveMove,
      bonusVal: unit.buffMoveDelta + unit.passiveMoveBonus,
      icon: Icons.directions_walk,
      accentColor: Colors.lightGreenAccent,
    );

    // 只有在添加了含有能量值的效果時，才會建立並顯示能量值 (Energy) 項目
    Widget? energyItem;
    if (unit.currentEnergy != null) {
      energyItem = _buildStatItem(
        context: context,
        provider: provider,
        statType: StatType.energy,
        baseVal: unit.currentEnergy!,
        effectiveVal: unit.currentEnergy!,
        bonusVal: 0,
        icon: Icons.bolt,
        accentColor: Colors.purpleAccent,
      );
    }

    // 小兵採用直向 (Column) 顯示所有數據項目 (HP, 護盾, ATK, RNG, MOV, 能量)
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: hpItem),
          const SizedBox(height: 2),
          Expanded(child: shieldItem),
          const SizedBox(height: 2),
          Expanded(child: atkItem),
          const SizedBox(height: 2),
          Expanded(child: rangeItem),
          const SizedBox(height: 2),
          Expanded(child: moveItem),
          if (energyItem != null) ...[
            const SizedBox(height: 2),
            Expanded(child: energyItem),
          ],
        ],
      );
    }

    // 英雄卡片採用 Row 顯示
    return Row(
      children: [
        Expanded(child: hpItem),
        const SizedBox(width: 4),
        Expanded(child: shieldItem),
        const SizedBox(width: 4),
        Expanded(child: atkItem),
        const SizedBox(width: 4),
        Expanded(child: rangeItem),
        const SizedBox(width: 4),
        Expanded(child: moveItem),
        if (energyItem != null) ...[
          const SizedBox(width: 4),
          Expanded(child: energyItem),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required BattleProvider provider,
    required StatType statType,
    required int baseVal,
    required int effectiveVal,
    required int bonusVal,
    required IconData icon,
    required Color accentColor,
  }) {
    return Tooltip(
      message: '點擊以算術運算調整 (${statType.displayName})',
      child: InkWell(
        onTap: () {
          ArithmeticInputDialog.show(
            context: context,
            unit: unit,
            statType: statType,
            onConfirm: (expression) {
              provider.applyArithmetic(
                unitId: unit.id,
                statType: statType,
                expression: expression,
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 4,
            vertical: isCompact ? 1 : 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF131924),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2E3A4E)),
          ),
          child: isCompact
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: UiScale.of(context).dp(12), color: accentColor),
                            const SizedBox(width: 3),
                            Text(
                              statType.shortCode,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: UiScale.of(context).sp(10.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$effectiveVal',
                              style: TextStyle(
                                color: bonusVal > 0
                                    ? Colors.greenAccent
                                    : bonusVal < 0
                                        ? Colors.redAccent
                                        : Colors.white,
                                fontSize: UiScale.of(context).sp(15),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (bonusVal != 0) ...[
                              const SizedBox(width: 1),
                              Text(
                                bonusVal > 0 ? '(+$bonusVal)' : '($bonusVal)',
                                style: TextStyle(
                                  color: bonusVal > 0 ? Colors.greenAccent : Colors.redAccent,
                                  fontSize: UiScale.of(context).sp(9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: UiScale.of(context).dp(13), color: accentColor),
                          const SizedBox(width: 2),
                          Text(
                            statType.shortCode,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: UiScale.of(context).sp(10.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$effectiveVal',
                            style: TextStyle(
                              color: bonusVal > 0
                                  ? Colors.greenAccent
                                  : bonusVal < 0
                                      ? Colors.redAccent
                                      : Colors.white,
                              fontSize: UiScale.of(context).sp(17),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (bonusVal != 0) ...[
                            const SizedBox(width: 1),
                            Text(
                              bonusVal > 0 ? '(+$bonusVal)' : '($bonusVal)',
                              style: TextStyle(
                                color: bonusVal > 0 ? Colors.greenAccent : Colors.redAccent,
                                fontSize: UiScale.of(context).sp(9.5),
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
    );
  }

  Widget _buildEffectsSection(BuildContext context, BattleProvider provider) {
    final maxVisible = unit.isHero ? 4 : 2;
    final totalEffects = unit.effects.length;
    final hasOverflow = totalEffects > maxVisible;
    final displayEffects = unit.effects.take(maxVisible).toList();
    final hasEnergy = unit.currentEnergy != null;

    // 小兵：第一行橫向展示效果 icons (最多 2 個效果 + 1 個 "+N")
    // 下一行靠右放置：+效果 與 +EN / EN設定 按鈕
    if (!unit.isHero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 第一行：最多兩個效果 + 溢出標籤
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 3,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...displayEffects.map((effect) => _buildEffectMiniBadge(context, provider, effect)),
                      if (hasOverflow)
                        InkWell(
                          onTap: () => _showAllEffectsDialog(context, provider),
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(40),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.amber.withAlpha(120), width: 0.8),
                            ),
                            child: Text(
                              '+${totalEffects - maxVisible}',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      if (unit.effects.isEmpty)
                        const Text(
                          '無效果',
                          style: TextStyle(color: Colors.white24, fontSize: 8.5),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // 第二行：按鈕靠右放置 (+效果 與 +EN / EN設定)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // +效果 按鈕
                InkWell(
                  onTap: () => _openAddEffectDialog(context, provider),
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(35),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.amber.withAlpha(100), width: 0.7),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 9, color: Colors.amber),
                        Text(
                          '效果',
                          style: TextStyle(color: Colors.amber, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                // +EN / EN設定 按鈕 (以紫色顯示)
                InkWell(
                  onTap: () => _openEnergyConfigDialog(context, provider),
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withAlpha(hasEnergy ? 50 : 25),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: hasEnergy ? Colors.purpleAccent : Colors.purpleAccent.withAlpha(120),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasEnergy ? Icons.settings : Icons.add,
                          size: 9,
                          color: Colors.purpleAccent,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          hasEnergy ? 'EN設定' : 'EN',
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 英雄卡片：效果在左側，+效果 與 +EN 按鈕在右側
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 顯示效果 icons
          Flexible(
            child: Wrap(
              spacing: 3,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...displayEffects.map((effect) => _buildEffectMiniBadge(context, provider, effect)),
                if (hasOverflow)
                  InkWell(
                    onTap: () => _showAllEffectsDialog(context, provider),
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(40),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.amber.withAlpha(120), width: 0.8),
                      ),
                      child: Text(
                        '+${totalEffects - maxVisible}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                if (unit.effects.isEmpty)
                  const Text(
                    '無狀態效果',
                    style: TextStyle(color: Colors.white24, fontSize: 9),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // 英雄的操作按鈕區：+效果 與 +EN / EN設定 按鈕
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _openAddEffectDialog(context, provider),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(35),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.withAlpha(100), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 10, color: Colors.amber),
                      Text(
                        '效果',
                        style: TextStyle(color: Colors.amber, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _openEnergyConfigDialog(context, provider),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withAlpha(hasEnergy ? 50 : 25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: hasEnergy ? Colors.purpleAccent : Colors.purpleAccent.withAlpha(120),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasEnergy ? Icons.settings : Icons.add,
                        size: 10,
                        color: Colors.purpleAccent,
                      ),
                      const SizedBox(width: 1),
                      Text(
                        hasEnergy ? 'EN設定' : '+EN',
                        style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 僅顯示 icon 和剩餘回合數的精簡標籤
  Widget _buildEffectMiniBadge(
      BuildContext context, BattleProvider provider, StatusEffect effect) {
    return Tooltip(
      message: '${effect.name}: ${effect.effectSummary} (點擊編輯)',
      child: InkWell(
        onTap: () {
          EffectDialog.show(
            context: context,
            unit: unit,
            initialEffect: effect,
            onSave: (updated) {
              provider.updateEffect(unitId: unit.id, updatedEffect: updated);
            },
            onDelete: () {
              provider.removeEffect(unitId: unit.id, effectId: effect.id);
            },
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: effect.color.withAlpha(40),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: effect.color.withAlpha(140), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(effect.iconData, size: 10, color: effect.color),
              const SizedBox(width: 2),
              Text(
                effect.isPermanent ? '∞' : '${effect.turnsRemaining}',
                style: TextStyle(
                  color: effect.color,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 點擊小兵等級按鈕時彈出選擇 Lv1 到 Lv3 的選單
  void _showLevelSelectMenu(BuildContext context, BattleProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2330),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.military_tech, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '設定 ${unit.name} 等級 (Level)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (unit.level != null)
                      TextButton(
                        onPressed: () {
                          provider.setMinionLevel(unitId: unit.id, level: null);
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('清除等級', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [1, 2, 3].map((lvl) {
                    final isSelected = unit.level == lvl;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : const Color(0xFF141923),
                            foregroundColor: isSelected ? Colors.black : Colors.white,
                            side: BorderSide(
                              color: isSelected ? Colors.amberAccent : const Color(0xFF2C394C),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            provider.setMinionLevel(unitId: unit.id, level: lvl);
                            Navigator.of(ctx).pop();
                          },
                          child: Text(
                            'Lv.$lvl',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 點擊單位名字時彈出查看與管理所有效果的彈窗 (玩家亦可在這裡更改小兵名字)
  void _showAllEffectsDialog(BuildContext context, BattleProvider provider) {
    final nameController = TextEditingController(text: unit.name);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2430),
              title: Row(
                children: [
                  Icon(
                    unit.isHero ? Icons.shield : Icons.pets,
                    color: isPlayer1 ? Colors.blueAccent : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            unit.name,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 若小兵有等級，在名字旁顯示當前等級
                        if (!unit.isHero && unit.level != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(50),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber, width: 0.8),
                            ),
                            child: Text(
                              'Lv.${unit.level}',
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 若有開啟能量值，在頂部顯示當前能量數值與能量值設定
                      if (unit.currentEnergy != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purpleAccent.withAlpha(100), width: 1.0),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt, size: 18, color: Colors.purpleAccent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '能量值: ${unit.currentEnergy} / ${unit.maxEnergy}  (每回合: ${unit.energyPerTurnDelta >= 0 ? "+${unit.energyPerTurnDelta}" : "${unit.energyPerTurnDelta}"})',
                                  style: const TextStyle(
                                    color: Colors.purpleAccent,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.purpleAccent,
                                  side: const BorderSide(color: Colors.purpleAccent, width: 0.8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.settings, size: 12),
                                label: const Text('EN設定', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _openEnergyConfigDialog(context, provider);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // 編輯小兵名稱區塊 (僅小兵可自訂更名)
                      if (!unit.isHero) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141923),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2E3A4E)),
                          ),
                          child: Row(
                            children: [
                              const Text('小兵名稱: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: nameController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: '輸入小兵名字',
                                    hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.tealAccent.shade700,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () {
                                  if (nameController.text.trim().isNotEmpty) {
                                    provider.renameUnit(unitId: unit.id, newName: nameController.text.trim());
                                    setDialogState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('已成功更新小兵名字'), duration: Duration(seconds: 1)),
                                    );
                                  }
                                },
                                child: const Text('儲存名字', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // 狀態效果列表
                      unit.effects.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  '目前沒有任何掛載狀態效果',
                                  style: TextStyle(color: Colors.white38, fontSize: 13),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: unit.effects.length,
                              separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
                              itemBuilder: (context, index) {
                                final effect = unit.effects[index];
                                return ListTile(
                                  dense: true,
                                  leading: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: effect.color.withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(effect.iconData, size: 18, color: effect.color),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        effect.name,
                                        style: TextStyle(
                                          color: effect.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          effect.isPermanent ? '永久' : '剩餘 ${effect.turnsRemaining} 回合',
                                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    effect.effectSummary +
                                        (effect.hasEnergy
                                            ? ' (能量: ${unit.currentEnergy ?? effect.initialEnergy}/${effect.maxEnergy})'
                                            : ''),
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.amberAccent),
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      EffectDialog.show(
                                        context: context,
                                        unit: unit,
                                        initialEffect: effect,
                                        onSave: (updated) {
                                          provider.updateEffect(unitId: unit.id, updatedEffect: updated);
                                        },
                                        onDelete: () {
                                          provider.removeEffect(unitId: unit.id, effectId: effect.id);
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _openAddEffectDialog(context, provider);
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.amberAccent),
                  label: const Text('新增效果', style: TextStyle(color: Colors.amberAccent)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('關閉', style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAddEffectDialog(BuildContext context, BattleProvider provider) {
    EffectDialog.show(
      context: context,
      unit: unit,
      onSave: (effect) {
        provider.addEffect(unitId: unit.id, effect: effect);
      },
    );
  }

  void _openEnergyConfigDialog(BuildContext context, BattleProvider provider) {
    EnergyConfigDialog.show(
      context: context,
      unit: unit,
      onSave: ({
        required bool enabled,
        int? currentEnergy,
        int? energyPerTurnDelta,
        int? minEnergy,
        int? maxEnergy,
      }) {
        provider.configureUnitEnergy(
          unitId: unit.id,
          enabled: enabled,
          currentEnergy: currentEnergy,
          energyPerTurnDelta: energyPerTurnDelta,
          minEnergy: minEnergy,
          maxEnergy: maxEnergy,
        );
      },
    );
  }

  void _showDismissConfirm(BuildContext context, BattleProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2430),
        title: Text('撤退或擊殺 ${unit.name}？', style: const TextStyle(color: Colors.white)),
        content: const Text(
          '此操作將清空該槽位，存活小兵數量連動加成將隨之更新。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.dismissMinion(
                playerIndex: isPlayer1 ? 0 : 1,
                slotIndex: unit.slotIndex!,
                isKilled: true,
              );
            },
            child: const Text('確定清空', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
