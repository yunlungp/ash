import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/battle_provider.dart';
import 'minion_slot.dart';
import 'unit_card.dart';

class PlayerPanel extends StatelessWidget {
  final int playerIndex; // 0: Player 1 (左), 1: Player 2 (右)

  const PlayerPanel({
    super.key,
    required this.playerIndex,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BattleProvider>();
    final isPlayer1 = playerIndex == 0;
    final hero = isPlayer1 ? provider.player1 : provider.player2;
    final minions = isPlayer1 ? provider.player1Minions : provider.player2Minions;
    final isActiveTurn = provider.activePlayerIndex == playerIndex;
    final themeColor = isPlayer1 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF161C26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActiveTurn ? themeColor : const Color(0xFF283548),
          width: isActiveTurn ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isActiveTurn)
            BoxShadow(
              color: themeColor.withAlpha(50),
              blurRadius: 16,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 主卡片與小兵展示區 (縮小英雄所佔空間，預留更多高度給小兵)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLargeScreen = constraints.maxHeight >= 420;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 英雄主卡片 (頂部已整合「行動中」標籤，不再需要單獨的頂部藍紅條)
                        UnitCard(
                          unit: hero,
                          isPlayer1: isPlayer1,
                          isCompact: false,
                        ),
                        SizedBox(height: isLargeScreen ? 3 : 1),

                        // 下方 3 個小兵槽位
                        Expanded(
                          child: MinionsSection(
                            playerIndex: playerIndex,
                            minions: minions,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
