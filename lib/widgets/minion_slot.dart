import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_unit.dart';
import '../providers/battle_provider.dart';
import '../utils/ui_scale.dart';
import 'unit_card.dart';

/// 拖曳小兵的資料模型
class MinionDragData {
  final int fromPlayerIndex;
  final int fromSlotIndex;
  final CharacterUnit minion;

  const MinionDragData({
    required this.fromPlayerIndex,
    required this.fromSlotIndex,
    required this.minion,
  });
}

class MinionsSection extends StatelessWidget {
  final int playerIndex; // 0: P1, 1: P2
  final List<CharacterUnit?> minions;

  const MinionsSection({
    super.key,
    required this.playerIndex,
    required this.minions,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BattleProvider>();
    final isPlayer1 = playerIndex == 0;
    final aliveCount = minions.where((m) => m != null).length;
    // 檢查該玩家是否已達到生成 3 隻小兵上限 (包含在對方槽位的小兵)
    final totalSpawnedByPlayer = provider.getPlayerSpawnedMinionsCount(playerIndex);
    final canSummonMore = totalSpawnedByPlayer < 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 被動光環指示列 (含開關)
        _buildPassiveBuffIndicator(context, provider, aliveCount, isPlayer1),
        const SizedBox(height: 3),

        // 3 個小兵槽位
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _buildSlot(
                    context: context,
                    provider: provider,
                    slotIndex: i,
                    minion: minions.length > i ? minions[i] : null,
                    isPlayer1: isPlayer1,
                    canSummonMore: canSummonMore,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 3),

        // 下方操作提示：長按小兵可拖曳移動至對方小兵格子
        _buildDragDropHint(context, isPlayer1),
      ],
    );
  }

  /// 提示玩家長按小兵可拖曳移動
  Widget _buildDragDropHint(BuildContext context, bool isPlayer1) {
    final ui = UiScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ui.dp(6), vertical: ui.dp(2)),
      decoration: BoxDecoration(
        color: const Color(0xFF131822),
        borderRadius: BorderRadius.circular(ui.dp(4)),
        border: Border.all(color: const Color(0xFF273344), width: 0.6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: ui.dp(12),
            color: isPlayer1 ? Colors.blueAccent : Colors.redAccent,
          ),
          SizedBox(width: ui.dp(4)),
          Flexible(
            child: Text(
              '提示：長按小兵可拖曳移至對方格子',
              style: TextStyle(
                color: Colors.white70,
                fontSize: ui.sp(9.5),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 顯示小兵數量連動被動增益的狀態條 (右方設有被動開關 Switch)
  Widget _buildPassiveBuffIndicator(BuildContext context, BattleProvider provider, int aliveCount, bool isPlayer1) {
    final color = isPlayer1 ? Colors.blueAccent : Colors.redAccent;
    final isPassiveOn = provider.isPassiveEnabled(playerIndex);
    final ui = UiScale.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ui.dp(6), vertical: ui.dp(2)),
      decoration: BoxDecoration(
        color: const Color(0xFF131822),
        borderRadius: BorderRadius.circular(ui.dp(5)),
        border: Border.all(
          color: isPassiveOn ? const Color(0xFF273344) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hub,
            size: ui.dp(12),
            color: isPassiveOn ? color : Colors.white24,
          ),
          SizedBox(width: ui.dp(4)),
          Text(
            '小兵 ($aliveCount/3): ',
            style: TextStyle(
              color: isPassiveOn ? Colors.white70 : Colors.white38,
              fontSize: ui.sp(9.5),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Opacity(
                opacity: isPassiveOn ? 1.0 : 0.35,
                child: Row(
                  children: [
                    _buffBadge(ui, '1: RNG+1', aliveCount >= 1 && isPassiveOn),
                    SizedBox(width: ui.dp(4)),
                    _buffBadge(ui, '2: MOV+1', aliveCount >= 2 && isPassiveOn),
                    SizedBox(width: ui.dp(4)),
                    _buffBadge(ui, '3: ATK+10', aliveCount >= 3 && isPassiveOn),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: ui.dp(4)),
          // 右方設置開關：預設開，只有打開小兵才會根據數量增加效果，反之不增加
          Tooltip(
            message: isPassiveOn ? '小兵數量被動加成：已開啟' : '小兵數量被動加成：已關閉',
            child: Transform.scale(
              scale: ui.scale >= 1.2 ? 0.8 : 0.65,
              child: Switch(
                value: isPassiveOn,
                activeThumbColor: color,
                activeTrackColor: color.withAlpha(90),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white12,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) {
                  provider.togglePassiveEnabled(playerIndex);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buffBadge(UiScale ui, String text, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ui.dp(4), vertical: ui.dp(1.5)),
      decoration: BoxDecoration(
        color: isActive ? Colors.amber.withAlpha(50) : Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(ui.dp(3)),
        border: Border.all(
          color: isActive ? Colors.amber : Colors.white24,
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.amberAccent : Colors.white38,
          fontSize: ui.sp(9),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSlot({
    required BuildContext context,
    required BattleProvider provider,
    required int slotIndex,
    required CharacterUnit? minion,
    required bool isPlayer1,
    required bool canSummonMore,
  }) {
    return DragTarget<MinionDragData>(
      onWillAcceptWithDetails: (details) {
        // 只有在當前格子是空的，且目標玩家生成小兵數量未滿（或來源就是同一個玩家的移動）
        return minion == null;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        // 移到對方槽位時，檢查該小兵的原擁有者在場上數量（本身已佔 1 名額，因此轉移不佔額外名額）
        provider.moveMinionToSlot(
          fromPlayerIndex: data.fromPlayerIndex,
          fromSlotIndex: data.fromSlotIndex,
          toPlayerIndex: playerIndex,
          toSlotIndex: slotIndex,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        if (minion != null) {
          // 有小兵：支援 LongPressDraggable
          return LongPressDraggable<MinionDragData>(
            data: MinionDragData(
              fromPlayerIndex: playerIndex,
              fromSlotIndex: slotIndex,
              minion: minion,
            ),
            delay: const Duration(milliseconds: 150),
            feedback: Material(
              color: Colors.transparent,
              child: Opacity(
                opacity: 0.85,
                child: SizedBox(
                  width: 130,
                  height: 120,
                  child: UnitCard(
                    unit: minion,
                    isPlayer1: isPlayer1,
                    isCompact: true,
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: UnitCard(
                unit: minion,
                isPlayer1: isPlayer1,
                isCompact: true,
              ),
            ),
            child: UnitCard(
              unit: minion,
              isPlayer1: isPlayer1,
              isCompact: true,
            ),
          );
        }

        // 空白槽位：虛線外框、召喚按鈕或拖曳目標高亮提示
        return InkWell(
          onTap: canSummonMore
              ? () {
                  provider.summonMinion(
                    playerIndex: playerIndex,
                    slotIndex: slotIndex,
                  );
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已達到 3 隻小兵上限（包含已移動至對方槽位的小兵）'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isHovering
                  ? Colors.tealAccent.withAlpha(30)
                  : const Color(0xFF141924),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovering
                    ? Colors.tealAccent
                    : const Color(0xFF334155),
                width: isHovering ? 2.0 : 1.1,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isHovering
                            ? Colors.tealAccent.withAlpha(50)
                            : canSummonMore
                                ? (isPlayer1 ? Colors.blueAccent : Colors.redAccent).withAlpha(30)
                                : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isHovering
                            ? Icons.move_to_inbox
                            : canSummonMore
                                ? Icons.add
                                : Icons.block,
                        size: 15,
                        color: isHovering
                            ? Colors.tealAccent
                            : canSummonMore
                                ? (isPlayer1 ? Colors.blueAccent : Colors.redAccent)
                                : Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isHovering ? '放開移入' : '槽位 #${slotIndex + 1}',
                      style: TextStyle(
                        color: isHovering ? Colors.tealAccent : Colors.white54,
                        fontSize: 10,
                        fontWeight: isHovering ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isHovering
                          ? '放置小兵'
                          : canSummonMore
                              ? '點擊召喚'
                              : '已達上限(3/3)',
                      style: TextStyle(
                        color: isHovering
                            ? Colors.tealAccent
                            : canSummonMore
                                ? (isPlayer1 ? Colors.blueAccent : Colors.redAccent)
                                : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
