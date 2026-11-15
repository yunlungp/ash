import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character_unit.dart';
import '../../models/skill_card.dart';
import '../../providers/battle_provider.dart';

class SkillDialog extends StatefulWidget {
  final int playerIndex;

  const SkillDialog({
    super.key,
    required this.playerIndex,
  });

  static Future<void> show({
    required BuildContext context,
    required int playerIndex,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => SkillDialog(playerIndex: playerIndex),
    );
  }

  @override
  State<SkillDialog> createState() => _SkillDialogState();
}

class _SkillDialogState extends State<SkillDialog> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BattleProvider>();
    final hero = provider.getHero(widget.playerIndex);
    final isPlayer1 = widget.playerIndex == 0;
    final themeColor = isPlayer1 ? Colors.blueAccent : Colors.redAccent;
    final cards = SkillCardDatabase.getCardsForHero(hero.presetId ?? '');

    final screenHeight = MediaQuery.of(context).size.height;
    final dialogMaxHeight = math.min(380.0, screenHeight * 0.95);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: const Color(0xFF151A24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: themeColor.withAlpha(120), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: dialogMaxHeight),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 頂部標題與關閉
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: themeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${hero.name} 技能與專屬技能卡',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // Eris 專屬印記計數器區塊
              if (hero.presetId == 'eris') ...[
                _buildErisMarkDashboard(context, provider, themeColor),
                const SizedBox(height: 8),
              ],

              // 技能卡內容列表
              Expanded(
                child: cards.isEmpty
                    ? Center(
                        child: Text(
                          '【${hero.name}】目前暫無專屬技能卡配置',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        itemCount: cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return _buildCardItem(context, provider, hero, card, themeColor);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(
    BuildContext context,
    BattleProvider provider,
    CharacterUnit hero,
    SkillCard card,
    Color themeColor,
  ) {
    final copies = card.isHeroInnate
        ? 1
        : provider.getSkillCardCopies(widget.playerIndex, card.id);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2638),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: copies > 0 ? themeColor.withAlpha(150) : const Color(0xFF2E3D52),
          width: copies > 0 ? 1.4 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 卡片 Header：名稱 + 副標題 + 持有數量調整器
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: card.isHeroInnate ? Colors.amber.withAlpha(40) : Colors.purple.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  card.isHeroInnate ? '固有技能' : '技能卡',
                  style: TextStyle(
                    color: card.isHeroInnate ? Colors.amberAccent : Colors.purpleAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• ${card.subtitle}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const Spacer(),
              // 非固有技能卡可調整持有張數 (0, 1, 2)
              if (!card.isHeroInnate) ...[
                const Text('持有: ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                _countBadge(
                  label: '0',
                  isSelected: copies == 0,
                  onTap: () => provider.setSkillCardCopies(
                    playerIndex: widget.playerIndex,
                    cardId: card.id,
                    copies: 0,
                  ),
                ),
                _countBadge(
                  label: '1張',
                  isSelected: copies == 1,
                  activeColor: themeColor,
                  onTap: () => provider.setSkillCardCopies(
                    playerIndex: widget.playerIndex,
                    cardId: card.id,
                    copies: 1,
                  ),
                ),
                _countBadge(
                  label: '2張',
                  isSelected: copies == 2,
                  activeColor: themeColor,
                  onTap: () => provider.setSkillCardCopies(
                    playerIndex: widget.playerIndex,
                    cardId: card.id,
                    copies: 2,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // 效果列表
          Column(
            children: card.effects.map((effect) {
              return _buildEffectRow(context, provider, hero, card, effect, copies, themeColor);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _countBadge({
    required String label,
    required bool isSelected,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = activeColor ?? Colors.blueAccent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(50) : const Color(0xFF141923),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEffectRow(
    BuildContext context,
    BattleProvider provider,
    CharacterUnit hero,
    SkillCard card,
    SkillEffect effect,
    int cardCopies,
    Color themeColor,
  ) {
    final isPassive = effect.type == SkillType.passive;
    final maxUses = provider.getMaxSkillUsesPerTurn(widget.playerIndex, effect, card);
    final usedCount = provider.getSkillUsedCount(effect.id);
    final canUse = !isPassive && cardCopies > 0 && usedCount < maxUses;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141924),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      effect.name,
                      style: TextStyle(
                        color: isPassive ? Colors.cyanAccent : Colors.amberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isPassive && cardCopies > 0 && maxUses < 90) ...[
                      const SizedBox(width: 6),
                      Text(
                        '本回合: $usedCount / $maxUses 次',
                        style: TextStyle(
                          color: usedCount >= maxUses ? Colors.redAccent : Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    if (effect.hpCost > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(40),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '消耗 ${effect.hpCost} HP',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 9.5),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  effect.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 右側按鈕：被動顯示常駐標籤，主動顯示發動按鈕
          if (isPassive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cardCopies > 0 ? Colors.cyan.withAlpha(40) : Colors.white12,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: cardCopies > 0 ? Colors.cyanAccent : Colors.white24,
                  width: 1,
                ),
              ),
              child: Text(
                cardCopies > 0 ? '常駐生效中' : '未持有',
                style: TextStyle(
                  color: cardCopies > 0 ? Colors.cyanAccent : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: canUse
                  ? () => _onExecuteSkillPressed(context, provider, hero, card, effect)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                usedCount >= maxUses && cardCopies > 0 ? '已達上限' : '發動',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  /// 處理點擊「發動」後的目標選擇與分支流程
  void _onExecuteSkillPressed(
    BuildContext context,
    BattleProvider provider,
    CharacterUnit hero,
    SkillCard card,
    SkillEffect effect,
  ) {
    // 1. [Eris 技能卡 1 效果 3: 印記穿梭] -> 彈窗選擇釋放佔領點或 -20 生命
    if (effect.id == 'eris_c1_eff3') {
      _showErisTeleportCostDialog(context, provider, card, effect, hero);
      return;
    }

    // 2. [Eris 技能卡 2 效果 2: 回收印記] -> 彈窗選擇回收 4, 5, 10 檔位
    if (effect.id == 'eris_c2_eff2') {
      _showErisRecycleTierDialog(context, provider);
      return;
    }

    // 3. [Eris 固有效果: 引爆印記傷害] -> 選擇敵方目標 + 設定扣除印記數
    if (effect.id == 'eris_innate_trigger') {
      final curMarks = provider.getErisMarks(widget.playerIndex);
      if (curMarks <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('場上目前沒有印記可供引爆'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }
      final candidates = _gatherCandidates(provider, SkillTargetType.enemyUnit);
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('敵方場上沒有可受傷害的單位'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }
      _showTargetPicker(context, candidates, (target) {
        _showErisTriggerMarkDialog(context, provider, target);
      });
      return;
    }

    // 4. [Eris 固有效果 1: 放置印記] -> 自動 +1 印記 (不超過上限)
    if (effect.id == 'eris_innate_1') {
      final curMarks = provider.getErisMarks(widget.playerIndex);
      final maxMarks = provider.getErisMaxMarks(widget.playerIndex);
      if (curMarks >= maxMarks) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('場上印記已達上限 ($maxMarks 個)'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }
      provider.executeSkill(
        playerIndex: widget.playerIndex,
        card: card,
        effect: effect,
      );
      return;
    }

    // 5. [Tinna 固有效果 2: 消耗 2 能量 或 10 生命召喚 Lv.1 小兵]
    if (effect.id == 'tinna_innate_2') {
      _showTinnaSummonCostDialog(context, provider, card, effect, hero);
      return;
    }

    // 6. [Tinna 技能卡 2: 抵消致命傷害 (破壞此卡 vs 犧牲 Lv.3 小兵)]
    if (effect.id == 'tinna_c2_eff') {
      _showTinnaFatalShieldDialog(context, provider, card, effect);
      return;
    }

    // 檢查生命值代價是否足夠
    if (effect.hpCost > 0 && hero.baseHp <= effect.hpCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生命值不足以支付代價 (需 ${effect.hpCost} HP)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 檢查特殊前置條件：例如 Luna 技能卡 1 效果 2 要求 HP <= 30 (30 或以下)
    if (effect.id == 'luna_c1_eff2' && hero.baseHp > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('發動失敗：當前生命值未在 30 或以下'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // 若需要指定目標
    if (effect.targetType != SkillTargetType.none) {
      final candidates = _gatherCandidates(provider, effect.targetType);
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('場上沒有符合條件的目標單位'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      _showTargetPicker(context, candidates, (selectedUnit) {
        provider.executeSkill(
          playerIndex: widget.playerIndex,
          card: card,
          effect: effect,
          targetUnit: selectedUnit,
        );
      });
    } else {
      // 無需指定目標直接發動
      provider.executeSkill(
        playerIndex: widget.playerIndex,
        card: card,
        effect: effect,
      );
    }
  }

  // --- Eris 專屬面板組件與對話框 ---

  Widget _buildErisMarkDashboard(BuildContext context, BattleProvider provider, Color themeColor) {
    final marks = provider.getErisMarks(widget.playerIndex);
    final maxMarks = provider.getErisMaxMarks(widget.playerIndex);
    final dmgPerMark = provider.getErisMarkDamage(widget.playerIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10141D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withAlpha(100), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.gps_fixed, color: Colors.amberAccent, size: 16),
          const SizedBox(width: 6),
          Text(
            '場上印記: $marks / $maxMarks',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(單個傷害: $dmgPerMark)',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const Spacer(),
          // 手動增減印記按鈕
          _miniMarkBtn('-1', () => provider.setErisMarks(widget.playerIndex, marks - 1)),
          const SizedBox(width: 4),
          _miniMarkBtn('+1', () => provider.setErisMarks(widget.playerIndex, marks + 1)),
          const SizedBox(width: 4),
          _miniMarkBtn('清空', () => provider.setErisMarks(widget.playerIndex, 0), color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _miniMarkBtn(String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? Colors.amberAccent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: c.withAlpha(35),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.withAlpha(120), width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Eris 傳送代價選擇 (釋放佔領點 vs 扣除 20 生命)
  void _showErisTeleportCostDialog(
    BuildContext context,
    BattleProvider provider,
    SkillCard card,
    SkillEffect effect,
    CharacterUnit hero,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2332),
        title: const Text('印記穿梭：請選擇發動代價', style: TextStyle(color: Colors.white, fontSize: 14)),
        content: const Text(
          '你可以選擇「釋放你已佔領的佔領點」或是「扣除自身 20 點生命值」，傳送至任意印記格子。',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // 釋放佔領點 (hpCost: 0)
              provider.executeSkill(
                playerIndex: widget.playerIndex,
                card: card,
                effect: const SkillEffect(
                  id: 'eris_c1_eff3',
                  name: '印記穿梭 (釋放佔領點)',
                  description: '釋放已佔領的佔領點，傳送至任意印記格子',
                  hpCost: 0,
                ),
              );
            },
            child: const Text('釋放佔領點', style: TextStyle(color: Colors.cyanAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (hero.baseHp <= 20) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('生命值不足 20 HP，無法支付'), backgroundColor: Colors.redAccent),
                );
                return;
              }
              Navigator.of(ctx).pop();
              // 扣除 20 生命
              provider.executeSkill(
                playerIndex: widget.playerIndex,
                card: card,
                effect: effect,
                deductHpCost: 20,
              );
            },
            child: const Text('扣除 20 生命', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Eris 回收印記檔位選擇 (4 / 5 / 10)
  void _showErisRecycleTierDialog(BuildContext context, BattleProvider provider) {
    final curMarks = provider.getErisMarks(widget.playerIndex);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2332),
        title: Text('回收場上印記 (目前: $curMarks 個)', style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _recycleTierTile(ctx, provider, 4, '傳送去任意你標記的格子', curMarks >= 4),
            const SizedBox(height: 6),
            _recycleTierTile(ctx, provider, 5, '可以恢復 20 生命', curMarks >= 5),
            const SizedBox(height: 6),
            _recycleTierTile(ctx, provider, 10, '選擇任意佔領點來佔領 (含對方的)', curMarks >= 10),
          ],
        ),
      ),
    );
  }

  Widget _recycleTierTile(
    BuildContext ctx,
    BattleProvider provider,
    int tier,
    String desc,
    bool isAvailable,
  ) {
    return InkWell(
      onTap: isAvailable
          ? () {
              Navigator.of(ctx).pop();
              provider.recycleErisMarks(playerIndex: widget.playerIndex, tierMarks: tier);
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.amber.withAlpha(30) : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isAvailable ? Colors.amberAccent : Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.amberAccent : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$tier 個',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                desc,
                style: TextStyle(
                  color: isAvailable ? Colors.white : Colors.white38,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Eris 引爆印記傷害彈窗 (設定扣除印記數)
  void _showErisTriggerMarkDialog(
    BuildContext context,
    BattleProvider provider,
    CharacterUnit target,
  ) {
    final curMarks = provider.getErisMarks(widget.playerIndex);
    final dmgPerMark = provider.getErisMarkDamage(widget.playerIndex);
    int selectedMarks = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final totalDmg = selectedMarks * dmgPerMark;
          return AlertDialog(
            backgroundColor: const Color(0xFF1B2332),
            title: Text('引爆印記傷害 ➜ ${target.name}', style: const TextStyle(color: Colors.white, fontSize: 14)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '場上現有印記: $curMarks 個  (每印記傷害: $dmgPerMark 點)',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('消耗印記: ', style: TextStyle(color: Colors.white, fontSize: 13)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.amberAccent),
                      onPressed: selectedMarks > 1
                          ? () => setDialogState(() => selectedMarks--)
                          : null,
                    ),
                    Text(
                      '$selectedMarks',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.amberAccent),
                      onPressed: selectedMarks < curMarks
                          ? () => setDialogState(() => selectedMarks++)
                          : null,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withAlpha(100)),
                  ),
                  child: Text(
                    '預計對【${target.name}】造成 $totalDmg 傷害 (HP ${target.baseHp} ➜ ${math.max(0, target.baseHp - totalDmg)})',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('取消', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  provider.triggerErisMarkDamage(
                    playerIndex: widget.playerIndex,
                    targetUnit: target,
                    marksToConsume: selectedMarks,
                  );
                },
                child: const Text('確認引爆', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Tinna 召喚代價選擇 (消耗 2 能量 vs 消耗 10 生命)
  void _showTinnaSummonCostDialog(
    BuildContext context,
    BattleProvider provider,
    SkillCard card,
    SkillEffect effect,
    CharacterUnit hero,
  ) {
    // 檢查是否有空槽位
    final minions = widget.playerIndex == 0 ? provider.player1Minions : provider.player2Minions;
    final emptySlot = minions.indexWhere((m) => m == null);
    if (emptySlot == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('我方小兵槽位已滿 (最多3隻)，無法召喚'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    final curEnergy = hero.currentEnergy ?? 0;
    final canUseEnergy = curEnergy >= 2;
    final canUseHp = hero.baseHp > 10;

    if (!canUseEnergy && !canUseHp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('能量不足 (需2點) 且生命值不足 (需>10HP)，無法召喚'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2332),
        title: const Text('召喚 Lv.1 小兵：選擇支付代價', style: TextStyle(color: Colors.white, fontSize: 14)),
        content: Text(
          '目前能量: $curEnergy / 6   目前生命: ${hero.baseHp}\n請選擇要扣除 2 個能量或 10 點生命值：',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: canUseEnergy
                ? () {
                    Navigator.of(ctx).pop();
                    provider.executeSkill(
                      playerIndex: widget.playerIndex,
                      card: card,
                      effect: effect,
                      deductHpCost: 0,
                    );
                    provider.summonMinion(playerIndex: widget.playerIndex, slotIndex: emptySlot);
                  }
                : null,
            child: Text(
              '消耗 2 能量',
              style: TextStyle(color: canUseEnergy ? Colors.purpleAccent : Colors.white24),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: canUseHp
                ? () {
                    Navigator.of(ctx).pop();
                    provider.executeSkill(
                      playerIndex: widget.playerIndex,
                      card: card,
                      effect: effect,
                      deductHpCost: 10,
                    );
                    provider.summonMinion(playerIndex: widget.playerIndex, slotIndex: emptySlot);
                  }
                : null,
            child: const Text('消耗 10 生命', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Tinna 致命傷害抵消 (破壞卡片 vs 犧牲 Lv.3 小兵)
  void _showTinnaFatalShieldDialog(
    BuildContext context,
    BattleProvider provider,
    SkillCard card,
    SkillEffect effect,
  ) {
    final minions = (widget.playerIndex == 0 ? provider.player1Minions : provider.player2Minions)
        .whereType<CharacterUnit>()
        .where((m) => m.level == 3)
        .toList();
    final hasLv3 = minions.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2332),
        title: const Text('抵消致命傷害 (生命值不變)', style: TextStyle(color: Colors.white, fontSize: 14)),
        content: Text(
          hasLv3
              ? '受到致命傷害！您可以選擇「破壞此技能卡」或「犧牲場上 1 隻 Lv.3 小兵代替破壞」來抵消傷害並傳送至出生點/佔領點：'
              : '受到致命傷害！將「破壞此技能卡」來抵消傷害（生命值不變），並可傳送至出生點/佔領點：',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // 破壞一張卡
              final curCopies = provider.getSkillCardCopies(widget.playerIndex, card.id);
              if (curCopies > 0) {
                provider.setSkillCardCopies(
                  playerIndex: widget.playerIndex,
                  cardId: card.id,
                  copies: curCopies - 1,
                );
              }
              provider.executeSkill(
                playerIndex: widget.playerIndex,
                card: card,
                effect: effect,
              );
            },
            child: const Text('破壞此技能卡', style: TextStyle(color: Colors.orangeAccent)),
          ),
          if (hasLv3)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              onPressed: () {
                Navigator.of(ctx).pop();
                // 犧牲第一隻 Lv.3 小兵
                final lv3Minion = minions.first;
                if (lv3Minion.slotIndex != null) {
                  provider.dismissMinion(
                    playerIndex: widget.playerIndex,
                    slotIndex: lv3Minion.slotIndex!,
                    isKilled: true,
                  );
                }
                provider.executeSkill(
                  playerIndex: widget.playerIndex,
                  card: card,
                  effect: effect,
                  targetUnit: lv3Minion,
                );
              },
              child: const Text('犧牲 Lv.3 小兵代替', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  List<CharacterUnit> _gatherCandidates(BattleProvider provider, SkillTargetType type) {
    final pIndex = widget.playerIndex;
    final friendlyHero = provider.getHero(pIndex);
    final friendlyMinions = pIndex == 0 ? provider.player1Minions : provider.player2Minions;
    final enemyHero = provider.getHero(pIndex == 0 ? 1 : 0);
    final enemyMinions = pIndex == 0 ? provider.player2Minions : provider.player1Minions;

    final fMinions = friendlyMinions.whereType<CharacterUnit>().toList();
    final eMinions = enemyMinions.whereType<CharacterUnit>().toList();

    switch (type) {
      case SkillTargetType.self:
        return [friendlyHero];
      case SkillTargetType.friendlyMinion:
        return fMinions;
      case SkillTargetType.friendlyUnit:
        return [friendlyHero, ...fMinions];
      case SkillTargetType.enemyUnit:
        return [enemyHero, ...eMinions];
      case SkillTargetType.anyUnit:
        return [friendlyHero, ...fMinions, enemyHero, ...eMinions];
      case SkillTargetType.none:
        return [];
    }
  }

  void _showTargetPicker(
    BuildContext context,
    List<CharacterUnit> candidates,
    Function(CharacterUnit) onSelect,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B2332),
          title: const Text('請選擇發動目標單位', style: TextStyle(color: Colors.white, fontSize: 14)),
          content: SizedBox(
            width: 320,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: candidates.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, i) {
                final u = candidates[i];
                final isMine = u.originalOwnerIndex == widget.playerIndex;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    u.isHero ? Icons.shield : Icons.pets,
                    color: isMine ? Colors.blueAccent : Colors.redAccent,
                    size: 18,
                  ),
                  title: Text(
                    u.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'HP: ${u.baseHp} / ATK: ${u.baseAtk}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onSelect(u);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
